import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../core/config.dart';
import '../../core/season.dart';
import '../bucket/bucket_item.dart';
import '../bucket/bucket_store.dart';
import '../races/race.dart';
import '../races/race_store.dart';
import '../../core/settings.dart';
import 'journey_trail.dart';
import 'map_geometry.dart';
import 'places.dart';
import 'race_card.dart';
import 'season_filter.dart';
import '../../core/units.dart';
import '../../core/load_error.dart';

const Color _oceanColor = Color(0xFFAAD3DF);
const LatLng _saCentre = LatLng(-29.0, 24.5);

/// The "Journey" tab: a real, zoomable map of South Africa with the runner's
/// races pinned to their towns and joined by a route line (solid between
/// completed races, dashed to planned ones). Towns appear as you zoom in
/// (Cape Town suburbs at the deepest levels); several races in one town show as
/// a numbered pin that fans out when you zoom in.
class MapView extends StatefulWidget {
  final RaceStore store;
  final BucketStore bucket;
  final void Function(Race race) onEdit;
  final void Function(Place place) onAddAtPlace;
  final VoidCallback onShowList;

  const MapView({
    super.key,
    required this.store,
    required this.bucket,
    required this.onEdit,
    required this.onAddAtPlace,
    required this.onShowList,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  static const double _minZoom = 2.5;
  static const double _maxZoom = 18;
  static const double _fanZoom = 9.5; // zoom at which multi-race towns fan out
  static const double _clusterRadius = 28; // screen px
  // Map zoom at which each place tier (1..5) appears.
  static const List<double> _tierZoom = [4.0, 6.0, 7.5, 10.5, 12.0];
  static const double _cardWidth = 240;
  static const double _cardHeight = 170;
  static const double _pinW = 36;
  static const double _pinH = 44;

  final MapController _map = MapController();
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  bool _ready = false;
  Size _viewport = Size.zero;
  String? _selectedId;

  @override
  void dispose() {
    _anim.dispose();
    _tick.dispose();
    _map.dispose();
    super.dispose();
  }

  // ---- geometry -----------------------------------------------------------

  LatLng _latLng(Place p) => LatLng(p.lat, p.lng);

  Offset _toScreen(Place p) => _map.camera.latLngToScreenOffset(_latLng(p));

  bool _onScreen(Offset s, {double margin = 50}) =>
      s.dx > -margin &&
      s.dy > -margin &&
      s.dx < _viewport.width + margin &&
      s.dy < _viewport.height + margin;

  // ---- camera -------------------------------------------------------------

  /// Smoothly flies the camera to [centre] at [zoom].
  Future<void> _flyTo(LatLng centre, double zoom) async {
    if (!_ready) return;
    final from = _map.camera.center;
    final fromZoom = _map.camera.zoom;
    final toZoom = zoom.clamp(_minZoom, _maxZoom).toDouble();
    void tick() {
      final k = Curves.easeInOut.transform(_anim.value);
      _map.move(
        LatLng(
          from.latitude + (centre.latitude - from.latitude) * k,
          from.longitude + (centre.longitude - from.longitude) * k,
        ),
        fromZoom + (toZoom - fromZoom) * k,
      );
    }

    _anim.removeListener(tick);
    _anim.addListener(tick);
    try {
      await _anim.forward(from: 0).orCancel;
    } on TickerCanceled {
      // interrupted by another move
    } finally {
      _anim.removeListener(tick);
    }
  }

  void _zoomBy(double delta) {
    _flyTo(_map.camera.center, _map.camera.zoom + delta);
  }

  void _reset(List<RaceGroup> groups) {
    final c = _startView(groups);
    _flyTo(c.$1, c.$2);
  }

  /// Opening view: the runner's races, or the whole country.
  (LatLng, double) _startView(List<RaceGroup> groups) {
    if (groups.isEmpty) return (_saCentre, 4.9);
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final g in groups) {
      minLat = math.min(minLat, g.place.lat);
      maxLat = math.max(maxLat, g.place.lat);
      minLng = math.min(minLng, g.place.lng);
      maxLng = math.max(maxLng, g.place.lng);
    }
    final centre = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final span = math.max(maxLat - minLat, (maxLng - minLng) * 1.4);
    final zoom =
        span < 0.05 ? 11.0 : (8.4 - math.log(span) / math.ln2 * 0.9);
    return (centre, zoom.clamp(2.8, 11.0).toDouble());
  }

  void _zoomIntoCluster(MapCluster c) {
    final zoom = _map.camera.zoom;
    final singleTown = c.groups.length == 1;
    final target = singleTown ? math.max(_fanZoom + 0.5, zoom + 2) : zoom + 1.6;
    _flyTo(_map.camera.screenOffsetToLatLng(c.center), target);
  }

  /// Races that have a known town, oldest first.
  List<(Race, Place)> _chronological(List<Race> races) {
    final out = <(Race, Place)>[];
    for (final r in races) {
      final p = placeByName(r.locationName);
      if (p != null) out.add((r, p));
    }
    out.sort((a, b) => a.$1.date.compareTo(b.$1.date));
    return out;
  }

  /// The trail legs in screen space: one per pair of consecutive races in
  /// different towns, lighter when a planned race is involved.
  List<TrailLeg> _trailLegs(List<Race> races) {
    final stops = _chronological(races);
    final legs = <TrailLeg>[];
    for (var i = 1; i < stops.length; i++) {
      final a = stops[i - 1], b = stops[i];
      if (a.$2.key == b.$2.key) continue;
      final planned = a.$1.status == RaceStatus.planned ||
          b.$1.status == RaceStatus.planned;
      legs.add(TrailLeg(_toScreen(a.$2), _toScreen(b.$2), planned: planned));
    }
    return legs;
  }

  // ---- interaction --------------------------------------------------------

  void _select(String? id) {
    if (_selectedId != id) setState(() => _selectedId = id);
  }

  void _onTownTap(Place p) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('${p.name}, ${p.where}'),
          action: SnackBarAction(
            label: 'Add race here',
            onPressed: () => widget.onAddAtPlace(p),
          ),
        ),
      );
  }

  // ---- build --------------------------------------------------------------

  String get _tileUrl {
    const key = AppConfig.mapTilerKey;
    if (key.isEmpty) {
      return 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
    }
    return 'https://api.maptiler.com/maps/${AppConfig.mapStyle}/256/{z}/{x}/{y}.png?key=$key';
  }

  String get _attribution => AppConfig.mapTilerKey.isEmpty
      ? '\u00A9 OpenStreetMap contributors \u00A9 CARTO'
      : '\u00A9 MapTiler \u00A9 OpenStreetMap contributors';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.store, widget.bucket, settings]),
      builder: (context, _) {
        final store = widget.store;
        if (store.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (store.error != null && store.races.isEmpty) {
          return LoadError(
              title: 'Could not load your journey',
              message: store.error,
              onRetry: store.load);
        }

        final season = seasonFor(DateTime.now(), southern: store.southern);
        final grouped = groupRaces(store.races);
        final start = _startView(grouped.groups);

        return LayoutBuilder(builder: (context, c) {
          _viewport = Size(c.maxWidth, c.maxHeight);

          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColorFiltered(
                  colorFilter: seasonFilter(season),
                  child: FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: start.$1,
                      initialZoom: start.$2,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                      backgroundColor: _oceanColor,
                      cameraConstraint: const CameraConstraint.unconstrained(),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onMapReady: () => setState(() => _ready = true),
                      onPositionChanged: (_, __) => _tick.value++,
                      onTap: (_, __) => _select(null),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _tileUrl,
                        userAgentPackageName: 'com.runnersjourney.runners_journey',
                        retinaMode: RetinaMode.isHighDensity(context),
                        maxNativeZoom: 18,
                      ),
                    ],
                  ),
                ),
                if (settings.showTrail && _ready)
                  ValueListenableBuilder<int>(
                    valueListenable: _tick,
                    builder: (context, _, __) =>
                        JourneyTrail(legs: _trailLegs(store.races)),
                  ),
                ValueListenableBuilder<int>(
                  valueListenable: _tick,
                  builder: (context, _, __) =>
                      _overlay(grouped, store.races, widget.bucket.open),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Chip(
                    avatar: Icon(seasonIcon(season), size: 18),
                    label: Text(seasonLabel(season)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (grouped.unplaced.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ActionChip(
                      avatar: const Icon(Icons.location_off_outlined, size: 18),
                      label: Text('${grouped.unplaced.length} not on map'),
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onShowList,
                      tooltip:
                          'These races have no town chosen. Edit them to pick one.',
                    ),
                  ),
                Positioned(
                  right: 6,
                  bottom: 2,
                  child: IgnorePointer(
                    child: Text(
                      _attribution,
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.black54,
                          backgroundColor: Color(0x99FFFFFF)),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: null,
                        tooltip: 'Zoom in',
                        onPressed: () => _zoomBy(1),
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: null,
                        tooltip: 'Zoom out',
                        onPressed: () => _zoomBy(-1),
                        child: const Icon(Icons.remove),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: null,
                        tooltip: 'Show my races',
                        onPressed: () => _reset(grouped.groups),
                        child: const Icon(Icons.zoom_out_map),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  /// Markers and the race card, positioned in screen space so they stay a
  /// constant size while the map zooms underneath.
  Widget _overlay(
      GroupResult grouped, List<Race> allRaces, List<BucketItem> bucket) {
    if (!_ready) return const SizedBox.shrink();
    final scale = _map.camera.zoom;
    final clusters = clusterGroups(grouped.groups, _toScreen, _clusterRadius);
    final pinTips = <String, Offset>{};
    final children = <Widget>[];

    // Town dots for places without races, revealed by zoom level.
    // Bucket-list races, grouped by town (only those with a known town).
    final bucketByPlace = <String, List<BucketItem>>{};
    final bucketPlaces = <String, Place>{};
    for (final b in bucket) {
      final p = placeForBucket(b);
      if (p == null) continue;
      bucketByPlace.putIfAbsent(p.key, () => []).add(b);
      bucketPlaces[p.key] = p;
    }
    final racePlaces = {
      for (final g in grouped.groups) g.place.key,
      ...bucketByPlace.keys,
    };
    for (final p in kPlaces) {
      if (racePlaces.contains(p.key)) continue;
      if (scale < _tierZoom[p.tier - 1]) continue;
      final s = _toScreen(p);
      if (!_onScreen(s)) continue;
      children.add(_TownDot(place: p, at: s, onTap: () => _onTownTap(p)));
    }

    // Race pins.
    final pins = <Widget>[];
    Widget racePin(Race r, Offset tip) {
      pinTips[r.id ?? r.name] = tip;
      return _Pin(
        tip: tip,
        width: _pinW,
        height: _pinH,
        color: _statusColor(r.status),
        selected: (r.id ?? r.name) == _selectedId,
        onTap: () {
          final id = r.id ?? r.name;
          _select(id == _selectedId ? null : id);
        },
        onHover: () => _select(r.id ?? r.name),
        child: Icon(_statusIcon(r.status),
            size: 18,
            color: r.status == RaceStatus.planned
                ? const Color(0xFF2E7D32)
                : Colors.black87),
      );
    }

    for (final cl in clusters) {
      if (!_onScreen(cl.center, margin: 120)) continue;
      final onlyGroup = cl.groups.length == 1 ? cl.groups.first : null;
      if (onlyGroup != null &&
          onlyGroup.races.length > 1 &&
          scale >= _fanZoom) {
        // Zoomed in on a multi-race town: fan the races out around it.
        final centre = cl.center;
        pins.add(_CentreDot(at: centre));
        final offsets = fanOffsets(onlyGroup.races.length);
        for (var i = 0; i < onlyGroup.races.length; i++) {
          pins.add(racePin(onlyGroup.races[i], centre + offsets[i]));
        }
      } else if (cl.count == 1) {
        pins.add(racePin(cl.races.first, cl.center));
      } else {
        pins.add(_Pin(
          tip: cl.center,
          width: _pinW + 6,
          height: _pinH + 6,
          color: const Color(0xFFE90052),
          selected: false,
          onTap: () => _zoomIntoCluster(cl),
          onHover: null,
          child: Text(
            '${cl.count}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ));
      }
    }
    children.addAll(pins);

    // Grey pins for bucket-list races still to do. Nudged sideways when the
    // runner also has a race in the same town.
    final raceTowns = {for (final g in grouped.groups) g.place.key};
    bucketByPlace.forEach((town, list) {
      final place = bucketPlaces[town]!;
      var tip = _toScreen(place);
      if (!_onScreen(tip, margin: 120)) return;
      if (raceTowns.contains(town)) tip = tip + const Offset(22, 0);
      final id = 'bucket:$town';
      pinTips[id] = tip;
      children.add(_Pin(
        tip: tip,
        width: _pinW,
        height: _pinH,
        color: const Color(0xFF9E9E9E),
        selected: id == _selectedId,
        onTap: () => _select(id == _selectedId ? null : id),
        onHover: () => _select(id),
        child: list.length > 1
            ? Text('${list.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15))
            : const Icon(Icons.flag_outlined, size: 18, color: Colors.white),
      ));
    });

    // Race card for the selected pin.
    final tip = _selectedId == null ? null : pinTips[_selectedId];
    if (tip != null && _selectedId!.startsWith('bucket:')) {
      final town = _selectedId!.substring(7);
      final items = bucketByPlace[town] ?? const <BucketItem>[];
      final left = tip.dx - _cardWidth / 2;
      final maxLeft = math.max(8.0, _viewport.width - _cardWidth - 8);
      final cardH = 90.0 + items.length * 44;
      var top = tip.dy - _pinH - cardH - 6;
      if (top < 8) top = tip.dy + 10;
      children.add(Positioned(
        left: left.clamp(8.0, maxLeft).toDouble(),
        top: top,
        width: _cardWidth,
        child: Card(
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Bucket list \u00B7 $town',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _select(null),
                    ),
                  ],
                ),
                for (final it in items)
                  Row(
                    children: [
                      Checkbox(
                        value: it.done,
                        visualDensity: VisualDensity.compact,
                        onChanged: (v) {
                          widget.bucket.setDone(it, v ?? true);
                          _select(null);
                        },
                      ),
                      Expanded(
                        child: Text(
                          it.distanceKm == null
                              ? it.name
                              : '${it.name} (${formatDistance(it.distanceKm!)})',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ));
    } else if (tip != null) {
      Race? race;
      for (final r in allRaces) {
        if ((r.id ?? r.name) == _selectedId) race = r;
      }
      if (race != null) {
        final left = tip.dx - _cardWidth / 2;
        final maxLeft = math.max(8.0, _viewport.width - _cardWidth - 8);
        // Above the pin when there is room (anchored by its bottom edge, so
        // photos can make the card taller), otherwise just below it.
        final above = tip.dy - _pinH - _cardHeight - 6 >= 8;
        final selectedRace = race;
        children.add(Positioned(
          key: ValueKey('race-card-$_selectedId'),
          left: left.clamp(8.0, maxLeft).toDouble(),
          top: above ? null : tip.dy + 10,
          bottom: above ? _viewport.height - (tip.dy - _pinH - 6) : null,
          width: _cardWidth,
          child: RaceCard(
            race: selectedRace,
            onEdit: () => widget.onEdit(selectedRace),
            onClose: () => _select(null),
          ),
        ));
      }
    }

    return Stack(clipBehavior: Clip.hardEdge, children: children);
  }

  Color _statusColor(RaceStatus s) {
    switch (s) {
      case RaceStatus.completed:
        return const Color(0xFFF2B01E);
      case RaceStatus.dnf:
        return const Color(0xFFE67E22);
      case RaceStatus.dns:
        return const Color(0xFF9E9E9E);
      case RaceStatus.planned:
        return Colors.white;
    }
  }

  IconData _statusIcon(RaceStatus s) {
    switch (s) {
      case RaceStatus.completed:
        return Icons.emoji_events;
      case RaceStatus.dnf:
        return Icons.warning_amber_rounded;
      case RaceStatus.dns:
        return Icons.block;
      case RaceStatus.planned:
        return Icons.flag;
    }
  }
}

/// A teardrop pin whose tip sits on [tip].
class _Pin extends StatelessWidget {
  final Offset tip;
  final double width;
  final double height;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onHover;
  final Widget child;

  const _Pin({
    required this.tip,
    required this.width,
    required this.height,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.onHover,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final circle = width * 0.42; // radius of the round head
    return Positioned(
      left: tip.dx - width / 2,
      top: tip.dy - height,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: onHover == null ? null : (_) => onHover!(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onTap,
          child: AnimatedScale(
            scale: selected ? 1.15 : 1.0,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 120),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                      painter: _PinPainter(color: color, radius: circle)),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: circle * 2,
                  child: Center(child: child),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _PinPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final head = Offset(cx, radius);
    final path = Path()
      ..addOval(Rect.fromCircle(center: head, radius: radius))
      ..moveTo(cx - radius * 0.6, radius + radius * 0.8)
      ..lineTo(cx, size.height)
      ..lineTo(cx + radius * 0.6, radius + radius * 0.8)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, true);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) =>
      old.color != color || old.radius != radius;
}

class _CentreDot extends StatelessWidget {
  final Offset at;
  const _CentreDot({required this.at});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx - 5,
      top: at.dy - 5,
      child: IgnorePointer(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFE90052),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}

/// A small town marker with its name, shown at higher zoom levels.
class _TownDot extends StatelessWidget {
  final Place place;
  final Offset at;
  final VoidCallback onTap;

  const _TownDot({required this.place, required this.at, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx - 7,
      top: at.dy - 9,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: place.tier == 1
                    ? const Color(0xFFFFD54F)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black54, width: 2),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                place.name,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: place.tier == 1 ? 13 : 11,
                    fontWeight:
                        place.tier == 1 ? FontWeight.w800 : FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/season.dart';
import '../races/race.dart';
import '../races/race_store.dart';
import 'map_geometry.dart';
import 'places.dart';
import 'race_card.dart';
import 'season_filter.dart';

const String _mapAsset = 'assets/images/south_africa_map.jpg';
const double _mapAspect = 1672 / 941;
const Color _oceanColor = Color(0xFF0E4A5E);

/// The "Journey" tab: the illustrated South Africa map with races pinned to
/// their towns. Pinch / scroll to zoom. Towns appear as you zoom in; several
/// races in one town show as a numbered pin that fans out when you zoom in.
class MapView extends StatefulWidget {
  final RaceStore store;
  final void Function(Race race) onEdit;
  final void Function(Place place) onAddAtPlace;
  final VoidCallback onShowList;

  const MapView({
    super.key,
    required this.store,
    required this.onEdit,
    required this.onAddAtPlace,
    required this.onShowList,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  static const double _maxScale = 10;
  static const double _fanScale = 3.0; // zoom at which multi-race towns fan out
  static const double _clusterRadius = 28; // screen px
  static const List<double> _tierScale = [1.0, 2.0, 3.2];
  static const double _cardWidth = 240;
  static const double _cardHeight = 170;
  static const double _pinW = 36;
  static const double _pinH = 44;

  final TransformationController _tc = TransformationController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  Float64List? _from;
  Float64List? _to;

  Size _viewport = Size.zero;
  Rect _mapRect = Rect.zero;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _anim.addListener(_onTick);
  }

  @override
  void dispose() {
    _anim.dispose();
    _tc.dispose();
    super.dispose();
  }

  // ---- geometry -----------------------------------------------------------

  Rect _fit(Size v) {
    var w = v.width;
    var h = w / _mapAspect;
    if (h > v.height) {
      h = v.height;
      w = h * _mapAspect;
    }
    return Rect.fromLTWH((v.width - w) / 2, (v.height - h) / 2, w, h);
  }

  Offset _content(Place p) => Offset(
        _mapRect.left + p.fx * _mapRect.width,
        _mapRect.top + p.fy * _mapRect.height,
      );

  Offset _toScreen(Place p) =>
      MatrixUtils.transformPoint(_tc.value, _content(p));

  bool _onScreen(Offset s, {double margin = 50}) =>
      s.dx > -margin &&
      s.dy > -margin &&
      s.dx < _viewport.width + margin &&
      s.dy < _viewport.height + margin;

  // ---- zoom / animation ---------------------------------------------------

  Matrix4 _matrixFor(Offset content, double scale) {
    final s = scale.clamp(1.0, _maxScale).toDouble();
    var tx = _viewport.width / 2 - s * content.dx;
    var ty = _viewport.height / 2 - s * content.dy;
    tx = tx.clamp(_viewport.width - s * _viewport.width, 0.0).toDouble();
    ty = ty.clamp(_viewport.height - s * _viewport.height, 0.0).toDouble();
    return Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
  }

  void _animateTo(Matrix4 end) {
    _from = Float64List.fromList(_tc.value.storage);
    _to = Float64List.fromList(end.storage);
    _anim.forward(from: 0);
  }

  void _onTick() {
    final f = _from;
    final t = _to;
    if (f == null || t == null) return;
    final k = Curves.easeInOut.transform(_anim.value);
    final m = Matrix4.zero();
    for (var i = 0; i < 16; i++) {
      m.storage[i] = f[i] + (t[i] - f[i]) * k;
    }
    _tc.value = m;
  }

  void _zoomBy(double factor) {
    final center = Offset(_viewport.width / 2, _viewport.height / 2);
    final scale = _tc.value.getMaxScaleOnAxis() * factor;
    _animateTo(_matrixFor(_tc.toScene(center), scale));
  }

  void _reset() => _animateTo(Matrix4.identity());

  void _zoomIntoCluster(MapCluster c) {
    final scale = _tc.value.getMaxScaleOnAxis();
    final singleTown = c.groups.length == 1;
    final target = singleTown
        ? math.max(_fanScale + 0.6, scale * 2.0)
        : scale * 2.2;
    _animateTo(_matrixFor(_tc.toScene(c.center), target));
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
          content: Text('${p.name}, ${p.province}'),
          action: SnackBarAction(
            label: 'Add race here',
            onPressed: () => widget.onAddAtPlace(p),
          ),
        ),
      );
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        if (store.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (store.error != null && store.races.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load your journey.\n${store.error}',
                  textAlign: TextAlign.center),
            ),
          );
        }

        final season = seasonFor(DateTime.now(), southern: store.southern);
        final grouped = groupRaces(store.races);

        return LayoutBuilder(builder: (context, c) {
          final vp = Size(c.maxWidth, c.maxHeight);
          if (vp != _viewport) {
            final first = _viewport == Size.zero;
            _viewport = vp;
            if (!first) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _tc.value = Matrix4.identity();
              });
            }
          }
          _mapRect = _fit(vp);

          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: _oceanColor),
                InteractiveViewer(
                  transformationController: _tc,
                  minScale: 1,
                  maxScale: _maxScale,
                  child: SizedBox(
                    width: vp.width,
                    height: vp.height,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _select(null),
                      child: Stack(
                        children: [
                          Positioned.fromRect(
                            rect: _mapRect,
                            child: ColorFiltered(
                              colorFilter: seasonFilter(season),
                              child: Image.asset(
                                _mapAsset,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.medium,
                                gaplessPlayback: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _tc,
                  builder: (context, _) => _overlay(grouped, store.races),
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
                      label: Text(
                          '${grouped.unplaced.length} not on map'),
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onShowList,
                      tooltip:
                          'These races have no town chosen. Edit them to pick one.',
                    ),
                  ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: null,
                        tooltip: 'Zoom in',
                        onPressed: () => _zoomBy(1.8),
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: null,
                        tooltip: 'Zoom out',
                        onPressed: () => _zoomBy(1 / 1.8),
                        child: const Icon(Icons.remove),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: null,
                        tooltip: 'Show whole map',
                        onPressed: _reset,
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
  Widget _overlay(GroupResult grouped, List<Race> allRaces) {
    final scale = _tc.value.getMaxScaleOnAxis();
    final clusters = clusterGroups(grouped.groups, _toScreen, _clusterRadius);
    final pinTips = <String, Offset>{};
    final children = <Widget>[];

    // Town dots for places without races, revealed by zoom level.
    final racePlaces = {for (final g in grouped.groups) g.place.name};
    for (final p in kPlaces) {
      if (p.illustrated || racePlaces.contains(p.name)) continue;
      if (scale < _tierScale[p.tier - 1]) continue;
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
          scale >= _fanScale) {
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
          color: const Color(0xFF1B5E20),
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

    // Race card for the selected pin.
    final tip = _selectedId == null ? null : pinTips[_selectedId];
    if (tip != null) {
      Race? race;
      for (final r in allRaces) {
        if ((r.id ?? r.name) == _selectedId) race = r;
      }
      if (race != null) {
        final left = tip.dx - _cardWidth / 2;
        final maxLeft = math.max(8.0, _viewport.width - _cardWidth - 8);
        var top = tip.dy - _pinH - _cardHeight - 6;
        if (top < 8) top = tip.dy + 10;
        final selectedRace = race;
        children.add(Positioned(
          left: left.clamp(8.0, maxLeft).toDouble(),
          top: top,
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
            color: const Color(0xFF1B5E20),
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
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../../core/season.dart';
import '../../../core/settings.dart';
import '../season_filter.dart';
import '../spike/style_recolour.dart';
import 'map_engine.dart';
import 'dark_style.dart';
import 'map_overlay.dart';
import 'mercator.dart';
import 'pin_images.dart';
import 'style_tweaks.dart';

/// The OpenFreeMap map, drawn by MapLibre. The pins, trail and race card are
/// still Flutter widgets drawn over it from [camera], which is worked out in
/// Dart so it never waits on the map engine.
///
/// MapLibre's zoom is one lower than the app's (it uses 512 px tiles), so the
/// engine converts in both directions.
class MapLibreEngine implements MapEngine {
  static String _styleUrl(String name) =>
      'https://tiles.openfreemap.org/styles/$name';
  static final Map<String, String> _rawStyles = {}; // kept for the app's life

  LatLng _center = const LatLng(-29.0, 24.5);
  double _zoom = 4.9; // app units
  Size _size = const Size(400, 700);
  ml.MapLibreMapController? _controller;
  DateTime _lastMove = DateTime.fromMillisecondsSinceEpoch(0);
  MapEngineParams? _params;

  // ---- markers drawn by the map itself -----------------------------------

  MapOverlayData? _overlay;
  bool _layersReady = false;
  bool _syncing = false;
  bool _dirty = false;
  // Bumped whenever a new map (new controller) is created, so a send that was
  // still waiting on the old map is abandoned instead of blocking all later ones.
  int _gen = 0;
  final Set<String> _images = {};
  double _dpr = 2.7;

  static const _empty = {'type': 'FeatureCollection', 'features': []};

  @override
  bool get nativeOverlay => true;

  @override
  void setOverlay(MapOverlayData data) {
    _overlay = data;
    unawaited(_sync());
  }

  Future<void> _addNativeLayers() async {
    final c = _controller;
    if (c == null) return;
    _layersReady = false;
    _images.clear();
    final gen = _gen;
    await c.addGeoJsonSource('legs-done', _empty);
    await c.addLineLayer(
      'legs-done',
      'legs-done-line',
      const ml.LineLayerProperties(
        lineColor: '#0A3FA8',
        lineOpacity: ['get', 'a'],
        lineWidth: ['get', 'w'],
        lineCap: 'round',
        lineJoin: 'round',
        lineDasharray: [0.2, 2.6],
      ),
    );
    await c.addGeoJsonSource('legs-planned', _empty);
    await c.addLineLayer(
      'legs-planned',
      'legs-planned-line',
      const ml.LineLayerProperties(
        lineColor: '#0A3FA8',
        lineOpacity: ['get', 'a'],
        lineWidth: ['get', 'w'],
        lineCap: 'round',
        lineJoin: 'round',
        lineDasharray: [0.2, 4.0],
      ),
    );
    await c.addGeoJsonSource('towns', _empty);
    await c.addCircleLayer(
      'towns',
      'towns-dot',
      const ml.CircleLayerProperties(
        circleRadius: 7.0,
        circleColor: [
          'match',
          ['get', 'tier'],
          1,
          '#FFD54F',
          '#FFFFFF',
        ],
        circleStrokeColor: '#616161',
        circleStrokeWidth: 2.0,
      ),
    );
    await c.addSymbolLayer(
      'towns',
      'towns-label',
      const ml.SymbolLayerProperties(
        textField: ['get', 'name'],
        textFont: ['Noto Sans Bold'],
        textSize: 11.0,
        textAnchor: 'left',
        textOffset: [1.1, 0.0],
        textColor: '#222222',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 1.5,
      ),
    );
    await c.addGeoJsonSource('pins', _empty);
    await c.addSymbolLayer(
      'pins',
      'pins',
      ml.SymbolLayerProperties(
        iconImage: const ['get', 'img'],
        // Pictures are drawn at [kPinImageScale] pixels per point and the map
        // shows them at 1 / pixel ratio, so this restores their true size.
        iconSize: [
          'case',
          ['==', ['get', 'sel'], 1],
          _dpr / kPinImageScale * 1.15,
          _dpr / kPinImageScale,
        ],
        iconAnchor: const ['get', 'anc'],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        symbolSortKey: const ['get', 'z'],
      ),
    );
    if (gen == _gen) _layersReady = true;
  }

  /// Sends the latest markers to the map. Runs one at a time; if more arrive
  /// while it is busy it goes round again with the newest.
  Future<void> _sync() async {
    if (_syncing) {
      _dirty = true;
      return;
    }
    _syncing = true;
    final gen = _gen;
    try {
      do {
        _dirty = false;
        final c = _controller;
        final d = _overlay;
        if (c == null || d == null || !_layersReady) break;
        for (final p in d.pins) {
          final key = p.imageKey;
          if (_images.contains(key)) continue;
          final img = await renderPinImage(p);
          if (gen != _gen) return;
          await c.addImage(key, img);
          if (gen != _gen) return;
          _images.add(key);
        }
        if (gen != _gen) return;
        await c.setGeoJsonSource('pins', {
          'type': 'FeatureCollection',
          'features': [
            for (var i = 0; i < d.pins.length; i++) _pinFeature(d.pins[i], i),
          ],
        });
        await c.setGeoJsonSource('legs-done', _legs(d, planned: false));
        await c.setGeoJsonSource('legs-planned', _legs(d, planned: true));
        await c.setGeoJsonSource('towns', {
          'type': 'FeatureCollection',
          'features': [
            for (final t in d.towns)
              {
                'type': 'Feature',
                'properties': {'key': t.key, 'name': t.name, 'tier': t.tier},
                'geometry': {
                  'type': 'Point',
                  'coordinates': [t.pos.longitude, t.pos.latitude],
                },
              },
          ],
        });
      } while (_dirty);
    } catch (e) {
      debugPrint('Map overlay sync failed: $e');
    } finally {
      if (gen == _gen) _syncing = false;
    }
  }

  Map<String, dynamic> _pinFeature(NativePin p, int i) => {
        'type': 'Feature',
        'properties': {
          'id': p.id,
          'img': p.imageKey,
          'sel': p.selected ? 1 : 0,
          'anc': p.shape == PinShape.dot ? 'center' : 'bottom',
          // Later pins draw on top; the selected one always does.
          'z': i + (p.selected ? 100000 : 0),
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [p.pos.longitude, p.pos.latitude],
        },
      };

  Map<String, dynamic> _legs(MapOverlayData d, {required bool planned}) => {
        'type': 'FeatureCollection',
        'features': [
          for (final l in d.legs)
            if (l.planned == planned)
              {
                'type': 'Feature',
                'properties': {'a': l.alpha, 'w': l.width},
                'geometry': {
                  'type': 'LineString',
                  'coordinates': [
                    [l.a.longitude, l.a.latitude],
                    [l.b.longitude, l.b.latitude],
                  ],
                },
              },
        ],
      };

  /// The town dot or name nearest a tap, with a generous touch area (the dots
  /// are small).
  NativeTown? _townNear(math.Point<double> tap) {
    final d = _overlay;
    if (d == null) return null;
    final cam = camera;
    NativeTown? best;
    var bestDist = double.infinity;
    for (final t in d.towns) {
      final s = cam.toScreen(t.pos);
      final dx = tap.x - s.dx, dy = tap.y - s.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      final onName = dx > 0 && dx < 14 + t.name.length * 6.5 && dy.abs() < 12;
      if ((dist <= 24 || onName) && dist < bestDist) {
        best = t;
        bestDist = dist;
      }
    }
    return best;
  }

  Future<void> _onMapClick(math.Point<double> point) async {
    final c = _controller;
    final params = _params;
    if (params == null) return;
    try {
      if (c != null) {
        final hits = await c.queryRenderedFeatures(point, ['pins'], null);
        if (hits.isNotEmpty) {
          final props = ((hits.first as Map)['properties'] as Map?) ?? {};
          final id = props['id']?.toString();
          if (id != null) {
            params.onPinTap(id);
            return;
          }
        }
      }
      final town = _townNear(point);
      if (town != null) {
        params.onTownTap(town.key);
        return;
      }
    } catch (_) {}
    params.onTap();
  }

  @override
  String get attribution => 'OpenFreeMap © OpenMapTiles Data from OpenStreetMap';

  @override
  MapCam get camera => MercatorCam(_center, _zoom, _size);

  @override
  void move(LatLng centre, double zoom) {
    _center = centre;
    _zoom = zoom;
    _lastMove = DateTime.now();
    _controller?.moveCamera(ml.CameraUpdate.newLatLngZoom(
        ml.LatLng(centre.latitude, centre.longitude), zoom - 1));
    _params?.onCamera();
  }

  void _onControllerChanged() {
    final c = _controller;
    final pos = c?.cameraPosition;
    if (pos == null) return;
    // Right after we moved it ourselves, our own numbers are newer than the
    // ones coming back from the map.
    if (DateTime.now().difference(_lastMove).inMilliseconds > 150) {
      _center = LatLng(pos.target.latitude, pos.target.longitude);
      _zoom = pos.zoom + 1;
    }
    _params?.onCamera();
  }

  @override
  Widget build(BuildContext context, MapEngineParams params) {
    if (_params == null) {
      // First build: open at the view the screen asked for.
      _center = params.center;
      _zoom = params.zoom;
    }
    _params = params;
    return _MapLibreSurface(engine: this, params: params);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller = null;
    _layersReady = false;
  }

  /// The style with English place names and the season and vivid colours
  /// baked in. Falls back to the plain style address if it cannot be fetched.
  static Future<String> _styleFor(
      String name, Season season, bool vivid, bool dark) async {
    try {
      var raw = _rawStyles[name];
      if (raw == null) {
        final r = await http
            .get(Uri.parse(_styleUrl(name)))
            .timeout(const Duration(seconds: 15));
        if (r.statusCode != 200) throw 'status ${r.statusCode}';
        raw = r.body;
        _rawStyles[name] = raw;
      }
      final seasonal = recolourStyle(
          localiseLabels(raw), seasonMatrix(season, vivid: vivid));
      return dark ? darkenStyle(seasonal) : seasonal;
    } catch (_) {
      return _styleUrl(name);
    }
  }
}

class _MapLibreSurface extends StatefulWidget {
  final MapLibreEngine engine;
  final MapEngineParams params;
  const _MapLibreSurface({required this.engine, required this.params});

  @override
  State<_MapLibreSurface> createState() => _MapLibreSurfaceState();
}

class _MapLibreSurfaceState extends State<_MapLibreSurface> {
  String? _style;
  late String _signature = _sig(widget.params);
  bool _styleLoaded = false;
  bool _slow = false;
  int _attempt = 0;
  Timer? _slowTimer;

  static String _sig(MapEngineParams p) =>
      '${settings.openFreeMapStyle}|${p.season.name}|${p.vivid}|${p.dark}';

  @override
  void initState() {
    super.initState();
    _watchForSlowLoad();
    _load();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  /// If the map style has not loaded after a while (no signal, a blocked
  /// connection), say so and offer a retry instead of leaving a blank map.
  void _watchForSlowLoad() {
    _slowTimer?.cancel();
    _styleLoaded = false;
    _slow = false;
    _slowTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && !_styleLoaded) setState(() => _slow = true);
    });
  }

  void _retry() {
    setState(() {
      _attempt++;
      _style = null;
    });
    _watchForSlowLoad();
    _load();
  }

  @override
  void didUpdateWidget(covariant _MapLibreSurface old) {
    super.didUpdateWidget(old);
    final s = _sig(widget.params);
    if (s != _signature) {
      _signature = s;
      _watchForSlowLoad();
      _load();
    }
  }

  Future<void> _load() async {
    final p = widget.params;
    final style = await MapLibreEngine._styleFor(
        settings.openFreeMapStyle, p.season, p.vivid, p.dark);
    if (!mounted || _signature != _sig(widget.params)) return;
    setState(() => _style = style);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    e._dpr = MediaQuery.devicePixelRatioOf(context);
    final style = _style;
    return LayoutBuilder(builder: (context, box) {
      e._size = Size(box.maxWidth, box.maxHeight);
      final Widget map = style == null
          ? ColoredBox(
              color: widget.params.dark
                  ? const Color(0xFF14202B)
                  : const Color(0xFFAAD3DF),
              child: const SizedBox.expand(),
            )
          : _buildMap(style);
      return Stack(
        fit: StackFit.expand,
        children: [
          map,
          if (_slow && !_styleLoaded)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'The map is taking a while to load. Check your connection.',
                        ),
                      ),
                      TextButton(
                        onPressed: _retry,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildMap(String style) {
    final e = widget.engine;
    return ml.MapLibreMap(
      key: ValueKey('$_signature#$_attempt'),
      styleString: style,
      initialCameraPosition: ml.CameraPosition(
        target: ml.LatLng(e._center.latitude, e._center.longitude),
        zoom: e._zoom - 1,
      ),
      minMaxZoomPreference: ml.MinMaxZoomPreference(
          widget.params.minZoom - 1, widget.params.maxZoom - 1),
      trackCameraPosition: true,
      // Taps on our pins must also reach onMapClick (the spike needed this).
      featureTapsTriggersMapClick: true,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      compassEnabled: false,
      myLocationEnabled: false,
      onMapCreated: (c) {
        e._controller?.removeListener(e._onControllerChanged);
        e._gen++;
        e._syncing = false;
        e._dirty = false;
        e._layersReady = false;
        e._images.clear();
        e._controller = c;
        c.addListener(e._onControllerChanged);
      },
      onStyleLoadedCallback: () async {
        _slowTimer?.cancel();
        if (mounted) {
          setState(() {
            _styleLoaded = true;
            _slow = false;
          });
        }
        try {
          await e._addNativeLayers();
        } catch (err) {
          debugPrint('Map overlay layers failed: $err');
        }
        widget.params.onReady();
        unawaited(e._sync());
      },
      onMapClick: (point, _) => e._onMapClick(point),
    );
  }
}

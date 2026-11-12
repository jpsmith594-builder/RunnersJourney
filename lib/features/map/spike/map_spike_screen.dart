import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/season.dart';
import '../season_filter.dart';
import 'style_recolour.dart';

/// PHASE 0 SPIKE. A throwaway screen that tests whether MapLibre with
/// OpenFreeMap can do what the journey map needs: numbered pins, a dashed
/// trail, tapping a pin, a Flutter card placed from map coordinates, season
/// and vivid colours, and many pins at once. Nothing else in the app uses it.
/// Open it from Settings by long-pressing the version line.
class MapSpikeScreen extends StatefulWidget {
  const MapSpikeScreen({super.key});

  @override
  State<MapSpikeScreen> createState() => _MapSpikeScreenState();
}

class _Race {
  final String id, name, town, detail, kind;
  final double lat, lng;
  final String number;
  const _Race(this.id, this.name, this.town, this.detail, this.kind, this.lat,
      this.lng, this.number);
}

const _races = <_Race>[
  _Race('1', 'Two Oceans Half', 'Cape Town', '2:05:10', 'done', -33.97, 18.46, '1'),
  _Race('2', 'Cape Town Marathon', 'Cape Town', '4:12:44', 'done', -33.92, 18.42, '2'),
  _Race('3', 'Knysna Forest Marathon', 'Knysna', 'Planned', 'planned', -34.04, 23.05, ''),
  _Race('4', 'Nelson Mandela Bay Half', 'Gqeberha', '2:01:30', 'done', -33.96, 25.60, '3'),
  _Race('5', 'Comrades', 'Pietermaritzburg', '10:45:12', 'done', -29.60, 30.38, '4'),
  _Race('6', 'Spar Challenge', 'Durban', '0:58:03', 'done', -29.86, 31.02, '5'),
  _Race('7', 'Soweto Marathon', 'Soweto', '4:40:20', 'done', -26.27, 27.86, '6'),
  _Race('8', 'Om die Dam', 'Bela-Bela', '5:02:11', 'done', -24.88, 28.29, '7'),
  _Race('9', 'Berlin Marathon', 'Berlin', 'Bucket list', 'bucket', 52.52, 13.40, ''),
  _Race('10', 'New York Marathon', 'New York', 'Bucket list', 'bucket', 40.71, -74.00, ''),
];

typedef AsyncCallbackLike = Future<void> Function(String name, Uint8List bytes);

class _MapSpikeScreenState extends State<MapSpikeScreen> {
  static const _styles = ['liberty', 'bright', 'positron'];

  final Map<String, String> _rawStyles = {};
  String _styleName = 'liberty';
  Season _season = seasonFor(DateTime.now(), southern: true);
  bool _vivid = true;

  String? _styleJson;
  String? _error;
  MapLibreMapController? _c;
  CameraPosition _camera =
      const CameraPosition(target: LatLng(-29.0, 24.0), zoom: 4.6);

  final _watch = Stopwatch();
  int? _styleMs;
  int _extra = 0;
  _Race? _selected;
  double _pinScale = 0.34;
  Offset? _cardAt;
  String _lastTap = '-';
  String _lastProjection = '-';

  @override
  void initState() {
    super.initState();
    _loadStyle();
  }

  @override
  void dispose() {
    _c?.removeListener(_onCamera);
    super.dispose();
  }

  Future<void> _loadStyle() async {
    setState(() {
      _error = null;
      _styleJson = null;
    });
    try {
      var raw = _rawStyles[_styleName];
      if (raw == null) {
        final r = await http
            .get(Uri.parse('https://tiles.openfreemap.org/styles/$_styleName'))
            .timeout(const Duration(seconds: 20));
        if (r.statusCode != 200) throw 'Style server said ${r.statusCode}';
        raw = utf8.decode(r.bodyBytes);
        _rawStyles[_styleName] = raw;
      }
      final json = recolourStyle(raw, seasonMatrix(_season, vivid: _vivid));
      if (!mounted) return;
      _watch
        ..reset()
        ..start();
      setState(() {
        _selected = null;
        _cardAt = null;
        _styleJson = json;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load the map style: $e');
    }
  }

  // ----- map layers -------------------------------------------------------

  Map<String, dynamic> _pinsGeoJson() {
    final features = <Map<String, dynamic>>[
      for (final r in _races)
        {
          'type': 'Feature',
          'properties': {'id': r.id, 'icon': _iconName(r.kind, r.number)},
          'geometry': {
            'type': 'Point',
            'coordinates': [r.lng, r.lat],
          },
        },
    ];
    final rnd = math.Random(7);
    for (var i = 0; i < _extra; i++) {
      features.add({
        'type': 'Feature',
        'properties': {'id': 'x$i', 'icon': 'pin-done'},
        'geometry': {
          'type': 'Point',
          'coordinates': [
            17 + rnd.nextDouble() * 14,
            -34 + rnd.nextDouble() * 10,
          ],
        },
      });
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  /// One thin line per leg between finished races in date order; older legs
  /// are fainter (property "a" drives the opacity), like today's trail.
  Map<String, dynamic> _trailGeoJson() {
    final done = _races.where((r) => r.kind == 'done').toList();
    final legs = done.length - 1;
    return {
      'type': 'FeatureCollection',
      'features': [
        for (var i = 0; i < legs; i++)
          {
            'type': 'Feature',
            'properties': {'a': 0.2 + 0.3 * (legs <= 1 ? 1 : i / (legs - 1))},
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [done[i].lng, done[i].lat],
                [done[i + 1].lng, done[i + 1].lat],
              ],
            },
          },
      ],
    };
  }

  // ----- teardrop pin pictures ---------------------------------------------

  static String _iconName(String kind, String number) =>
      kind == 'done' && number.isNotEmpty ? 'pin-done-$number' : 'pin-$kind';

  final Map<String, Uint8List> _images = {};

  /// Draws the same teardrop as the current map (36 x 44 points) at 3x.
  Future<Uint8List> _pinPng(Color color, Color ink, String number) async {
    const k = 3.0;
    const w = 36.0 * k, h = 44.0 * k;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    const radius = w * 0.42;
    const cx = w / 2;
    final path = Path()
      ..addOval(Rect.fromCircle(center: const Offset(cx, radius), radius: radius))
      ..moveTo(cx - radius * 0.6, radius + radius * 0.8)
      ..lineTo(cx, h)
      ..lineTo(cx + radius * 0.6, radius + radius * 0.8)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * k
        ..color = Colors.white,
    );
    if (number.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: number,
          style: TextStyle(
              color: ink,
              fontSize: 14 * k,
              fontWeight: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, radius - tp.height / 2));
    }
    final img = await rec.endRecording().toImage(w.round(), h.round());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _addImages(AsyncCallbackLike add) async {
    Future<void> one(String name, Color color, Color ink, String n) async {
      final bytes = _images[name] ??= await _pinPng(color, ink, n);
      await add(name, bytes);
    }

    const gold = Color(0xFFF5B400), ink = Color(0xFF37003C);
    await one('pin-done', gold, ink, '');
    await one('pin-planned', const Color(0xFF7B2FBE), Colors.white, '');
    await one('pin-bucket', const Color(0xFF9E9E9E), Colors.white, '');
    for (final r in _races) {
      if (r.kind == 'done' && r.number.isNotEmpty) {
        await one('pin-done-${r.number}', gold, ink, r.number);
      }
    }
  }

  Future<void> _addPinLayer() async {
    final c = _c;
    if (c == null) return;
    await c.addSymbolLayer(
      'pins',
      'pins-icon',
      SymbolLayerProperties(
        iconImage: const ['get', 'icon'],
        iconSize: _pinScale,
        iconAnchor: 'bottom',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
    );
  }

  Future<void> _addLayers() async {
    final c = _c;
    if (c == null) return;
    try {
      await c.addGeoJsonSource('trail', _trailGeoJson());
      await c.addLineLayer(
        'trail',
        'trail-line',
        const LineLayerProperties(
          lineColor: '#0A3FA8',
          lineWidth: 1.6,
          lineOpacity: ['get', 'a'],
          lineCap: 'round',
          lineJoin: 'round',
          lineDasharray: [0.2, 3.0],
        ),
      );
      await _addImages((name, bytes) => c.addImage(name, bytes));
      await c.addGeoJsonSource('pins', _pinsGeoJson());
      await _addPinLayer();
      if (mounted) setState(() => _styleMs = _watch.elapsedMilliseconds);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not add the pins: $e');
    }
  }

  Future<void> _rescalePins(double v) async {
    setState(() => _pinScale = v);
    try {
      await _c?.removeLayer('pins-icon');
      await _addPinLayer();
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not resize the pins: $e');
    }
  }

  Future<void> _setExtra(int n) async {
    setState(() => _extra = n);
    try {
      await _c?.setGeoJsonSource('pins', _pinsGeoJson());
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not update the pins: $e');
    }
  }

  Future<void> _fitAll() async {
    final c = _c;
    if (c == null) return;
    final done = _races.where((r) => r.kind == 'done' || r.kind == 'planned');
    final lats = done.map((r) => r.lat);
    final lngs = done.map((r) => r.lng);
    await c.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
        northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
      ),
      left: 40,
      top: 120,
      right: 40,
      bottom: 220,
    ));
  }

  // ----- taps and the card ------------------------------------------------

  void _onCamera() {
    final c = _c;
    if (c == null) return;
    final cam = c.cameraPosition;
    if (cam != null) _camera = cam;
    _placeCard();
  }

  Future<void> _placeCard() async {
    final c = _c;
    final r = _selected;
    if (c == null || r == null) return;
    try {
      final p = await c.toScreenLocation(LatLng(r.lat, r.lng));
      if (!mounted || _selected != r) return;
      // On Android the projection comes back in physical pixels.
      final dpr = defaultTargetPlatform == TargetPlatform.android
          ? MediaQuery.of(context).devicePixelRatio
          : 1.0;
      setState(() {
        _lastProjection =
            'raw ${p.x.toStringAsFixed(0)},${p.y.toStringAsFixed(0)}  dpr ${dpr.toStringAsFixed(2)}';
        _cardAt = Offset(p.x / dpr, p.y / dpr);
      });
    } catch (_) {}
  }

  Future<void> _onTap(math.Point<double> point, LatLng latLng) async {
    final c = _c;
    if (c == null) return;
    _lastTap = '${point.x.toStringAsFixed(0)},${point.y.toStringAsFixed(0)}';
    try {
      final hits = await c.queryRenderedFeatures(point, ['pins-icon'], null);
      _Race? found;
      if (hits.isNotEmpty) {
        final props = (hits.first as Map)['properties'] as Map?;
        final id = props?['id']?.toString();
        for (final r in _races) {
          if (r.id == id) found = r;
        }
      }
      if (!mounted) return;
      setState(() {
        _selected = found;
        _cardAt = null;
      });
      if (found != null) await _placeCard();
    } catch (e) {
      if (mounted) setState(() => _error = 'Tap failed: $e');
    }
  }

  // ----- screen -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final json = _styleJson;
    return Scaffold(
      appBar: AppBar(title: const Text('Map spike (OpenFreeMap)')),
      body: Stack(
        children: [
          if (json != null)
            MapLibreMap(
              key: ValueKey('$_styleName|${_season.name}|$_vivid'),
              styleString: json,
              initialCameraPosition: _camera,
              trackCameraPosition: true,
              compassEnabled: false,
              featureTapsTriggersMapClick: true,
              onMapCreated: (c) {
                _c?.removeListener(_onCamera);
                _c = c;
                c.addListener(_onCamera);
              },
              onStyleLoadedCallback: _addLayers,
              onMapClick: _onTap,
            )
          else
            Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ),
          if (_selected != null && _cardAt != null) _card(context),
          Positioned(left: 8, bottom: 268, child: _credit()),
          Positioned(left: 0, right: 0, bottom: 0, child: _controls()),
          if (_error != null)
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Material(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _credit() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        color: Colors.white70,
        child: const Text(
          'OpenFreeMap © OpenMapTiles Data from OpenStreetMap',
          style: TextStyle(fontSize: 10, color: Colors.black87),
        ),
      );

  Widget _card(BuildContext context) {
    final r = _selected!;
    final at = _cardAt!;
    final w = MediaQuery.of(context).size.width;
    const cardW = 200.0;
    final left = (at.dx - cardW / 2).clamp(8.0, w - cardW - 8);
    final top = (at.dy - 112).clamp(8.0, 4000.0);
    return Positioned(
      left: left,
      top: top,
      width: cardW,
      child: IgnorePointer(
        child: Card(
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(r.town),
                Text(r.detail),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  for (final s in _styles)
                    ChoiceChip(
                      label: Text(s),
                      selected: _styleName == s,
                      onSelected: (_) {
                        _styleName = s;
                        _loadStyle();
                      },
                    ),
                ],
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (final s in Season.values)
                    ChoiceChip(
                      avatar: Icon(seasonIcon(s), size: 16),
                      label: Text(seasonLabel(s)),
                      selected: _season == s,
                      onSelected: (_) {
                        _season = s;
                        _loadStyle();
                      },
                    ),
                ],
              ),
              Row(
                children: [
                  const Text('Vivid'),
                  Switch(
                    value: _vivid,
                    onChanged: (v) {
                      _vivid = v;
                      _loadStyle();
                    },
                  ),
                  TextButton(onPressed: _fitAll, child: const Text('Fit races')),
                  TextButton(
                    onPressed: () => _setExtra(_extra == 0 ? 500 : 0),
                    child: Text(_extra == 0 ? '+500 pins' : 'Remove 500'),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Pin size'),
                  Expanded(
                    child: Slider(
                      min: 0.15,
                      max: 1.2,
                      value: _pinScale,
                      onChanged: (v) => setState(() => _pinScale = v),
                      onChangeEnd: _rescalePins,
                    ),
                  ),
                  Text(_pinScale.toStringAsFixed(2)),
                ],
              ),
              Text(
                'Pins ${_races.length + _extra}   Style ready in '
                '${_styleMs == null ? '-' : '$_styleMs ms'}\n'
                'Zoom ${_camera.zoom.toStringAsFixed(1)}   Last tap $_lastTap\n'
                'Card: $_lastProjection',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

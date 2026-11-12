import 'dart:convert';
import 'dart:math' as math;

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
          'properties': {'id': r.id, 'n': r.number, 'kind': r.kind},
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
        'properties': {'id': 'x$i', 'n': '${i + 1}', 'kind': 'done'},
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

  Map<String, dynamic> _trailGeoJson() {
    final done = _races.where((r) => r.kind == 'done');
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': <String, dynamic>{},
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              for (final r in done) [r.lng, r.lat]
            ],
          },
        },
      ],
    };
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
          lineColor: '#F5B400',
          lineWidth: 3.0,
          lineCap: 'round',
          lineJoin: 'round',
          lineDasharray: [1, 2],
        ),
      );
      await c.addGeoJsonSource('pins', _pinsGeoJson());
      await c.addCircleLayer(
        'pins',
        'pins-circle',
        const CircleLayerProperties(
          circleRadius: 13.0,
          circleColor: [
            'match',
            ['get', 'kind'],
            'done',
            '#F5B400',
            'planned',
            '#7B2FBE',
            'bucket',
            '#9E9E9E',
            '#F5B400',
          ],
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2.5,
        ),
      );
      await c.addSymbolLayer(
        'pins',
        'pins-number',
        const SymbolLayerProperties(
          textField: ['get', 'n'],
          textFont: ['Noto Sans Bold'],
          textSize: 12.0,
          textColor: '#37003C',
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
      );
      if (mounted) setState(() => _styleMs = _watch.elapsedMilliseconds);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not add the pins: $e');
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
      final hits = await c.queryRenderedFeatures(
          point, ['pins-circle', 'pins-number'], null);
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
          Positioned(left: 8, bottom: 214, child: _credit()),
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

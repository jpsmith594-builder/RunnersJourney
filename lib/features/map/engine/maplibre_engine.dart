import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../../core/season.dart';
import '../season_filter.dart';
import '../spike/style_recolour.dart';
import 'map_engine.dart';
import 'mercator.dart';

/// The OpenFreeMap map, drawn by MapLibre. The pins, trail and race card are
/// still Flutter widgets drawn over it from [camera], which is worked out in
/// Dart so it never waits on the map engine.
///
/// MapLibre's zoom is one lower than the app's (it uses 512 px tiles), so the
/// engine converts in both directions.
class MapLibreEngine implements MapEngine {
  static const _styleName = 'liberty';
  static const _styleUrl = 'https://tiles.openfreemap.org/styles/$_styleName';
  static String? _rawStyle; // kept for the life of the app

  LatLng _center = const LatLng(-29.0, 24.5);
  double _zoom = 4.9; // app units
  Size _size = const Size(400, 700);
  ml.MapLibreMapController? _controller;
  DateTime _lastMove = DateTime.fromMillisecondsSinceEpoch(0);
  MapEngineParams? _params;

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
  }

  /// The style with the season and vivid colours baked in. Falls back to the
  /// plain style address if the style cannot be fetched.
  static Future<String> _styleFor(Season season, bool vivid) async {
    try {
      var raw = _rawStyle;
      if (raw == null) {
        final r = await http
            .get(Uri.parse(_styleUrl))
            .timeout(const Duration(seconds: 15));
        if (r.statusCode != 200) throw 'status ${r.statusCode}';
        raw = r.body;
        _rawStyle = raw;
      }
      return recolourStyle(raw, seasonMatrix(season, vivid: vivid));
    } catch (_) {
      return _styleUrl;
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

  static String _sig(MapEngineParams p) => '${p.season.name}|${p.vivid}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _MapLibreSurface old) {
    super.didUpdateWidget(old);
    final s = _sig(widget.params);
    if (s != _signature) {
      _signature = s;
      _load();
    }
  }

  Future<void> _load() async {
    final p = widget.params;
    final style = await MapLibreEngine._styleFor(p.season, p.vivid);
    if (!mounted || _signature != _sig(widget.params)) return;
    setState(() => _style = style);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final style = _style;
    return LayoutBuilder(builder: (context, box) {
      e._size = Size(box.maxWidth, box.maxHeight);
      if (style == null) {
        return const ColoredBox(
          color: Color(0xFFAAD3DF),
          child: SizedBox.expand(),
        );
      }
      return ml.MapLibreMap(
        key: ValueKey(_signature),
        styleString: style,
        initialCameraPosition: ml.CameraPosition(
          target: ml.LatLng(e._center.latitude, e._center.longitude),
          zoom: e._zoom - 1,
        ),
        minMaxZoomPreference: ml.MinMaxZoomPreference(
            widget.params.minZoom - 1, widget.params.maxZoom - 1),
        trackCameraPosition: true,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        compassEnabled: false,
        myLocationEnabled: false,
        onMapCreated: (c) {
          e._controller?.removeListener(e._onControllerChanged);
          e._controller = c;
          c.addListener(e._onControllerChanged);
        },
        onStyleLoadedCallback: () => widget.params.onReady(),
        onMapClick: (_, __) => widget.params.onTap(),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/config.dart';
import '../../../core/season.dart';
import '../season_filter.dart';
import 'tile_failures.dart';

/// Where the map camera is and how to turn coordinates into screen positions.
/// Zoom is always in the app's own units (256 px tiles), whatever engine is
/// drawing the map, so the zoom levels used by the journey screen mean the
/// same thing for every engine.
abstract class MapCam {
  LatLng get center;
  double get zoom;
  Offset toScreen(LatLng p);
  LatLng toLatLng(Offset screen);
}

/// What the journey screen asks the map engine for.
class MapEngineParams {
  final LatLng center;
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final Season season;
  final bool vivid;

  /// The map has been drawn once; the camera can be used from now on.
  final VoidCallback onReady;

  /// The camera moved (pan, zoom or a programmatic move).
  final VoidCallback onCamera;

  /// The empty map was tapped.
  final VoidCallback onTap;

  const MapEngineParams({
    required this.center,
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.season,
    required this.vivid,
    required this.onReady,
    required this.onCamera,
    required this.onTap,
  });
}

/// The base map under the journey screen's pins, trail and race card. Pins,
/// trail and card are Flutter widgets drawn over the map from [camera], so
/// swapping the engine does not touch them.
abstract class MapEngine {
  /// The camera. Only valid after [MapEngineParams.onReady].
  MapCam get camera;

  /// Moves the camera without animation (the screen animates by calling this
  /// every frame).
  void move(LatLng centre, double zoom);

  /// The map itself: no pins, no trail.
  Widget build(BuildContext context, MapEngineParams params);

  /// The credit line the map provider requires.
  String get attribution;

  void dispose();
}

// ---------------------------------------------------------------------------

const Color _oceanColor = Color(0xFFAAD3DF);

/// The current map: flutter_map with MapTiler picture tiles (or a free map
/// when no key is set), coloured for the season with a colour filter.
class FlutterMapEngine implements MapEngine {
  final MapController _controller = MapController();

  /// Reports (once in a while) when tiles keep failing, so a blank map can be
  /// diagnosed from Sentry.
  final TileFailureReporter _failures = TileFailureReporter(
    send: (template, params) => Sentry.captureMessage(
      template,
      level: SentryLevel.warning,
      template: template,
      params: params,
    ),
  );

  String get _tileUrl {
    const key = AppConfig.mapTilerKey;
    if (key.isEmpty) {
      return 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
    }
    // {r} becomes "@2x" on sharp screens, so MapTiler sends one 512 px tile
    // per tile. Without it the map asks for four tiles to fill the same space.
    return 'https://api.maptiler.com/maps/${AppConfig.mapStyle}/256/{z}/{x}/{y}{r}.png?key=$key';
  }

  /// Used for any tile the main map service refuses, for example when the
  /// monthly allowance has run out, so the map never goes blank.
  static const _fallbackUrl =
      'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  /// Tiles are kept on the phone for two weeks (up to 300 MB), so panning back
  /// over places already seen does not ask the map service again.
  static final _tileProvider = NetworkTileProvider(
    cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
      maxCacheSize: 300 * 1000 * 1000,
      overrideFreshAge: const Duration(days: 14),
    ),
  );

  @override
  String get attribution => AppConfig.mapTilerKey.isEmpty
      ? '© OpenStreetMap contributors © CARTO'
      : '© MapTiler © OpenStreetMap contributors';

  @override
  MapCam get camera => _Cam(_controller.camera);

  @override
  void move(LatLng centre, double zoom) => _controller.move(centre, zoom);

  @override
  Widget build(BuildContext context, MapEngineParams p) {
    return ColorFiltered(
      colorFilter: seasonFilter(p.season, vivid: p.vivid),
      child: FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: p.center,
          initialZoom: p.zoom,
          minZoom: p.minZoom,
          maxZoom: p.maxZoom,
          backgroundColor: _oceanColor,
          cameraConstraint: const CameraConstraint.unconstrained(),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          onMapReady: p.onReady,
          onPositionChanged: (_, __) => p.onCamera(),
          onTap: (_, __) => p.onTap(),
        ),
        children: [
          TileLayer(
            urlTemplate: _tileUrl,
            fallbackUrl:
                AppConfig.mapTilerKey.isEmpty ? null : _fallbackUrl,
            tileProvider: _tileProvider,
            userAgentPackageName: 'com.runnersjourney.runners_journey',
            retinaMode: RetinaMode.isHighDensity(context),
            maxNativeZoom: 18,
            errorTileCallback: (tile, error, stackTrace) =>
                _failures.record(tile.coordinates.z, error),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() => _controller.dispose();
}

class _Cam implements MapCam {
  final MapCamera _c;
  const _Cam(this._c);

  @override
  LatLng get center => _c.center;

  @override
  double get zoom => _c.zoom;

  @override
  Offset toScreen(LatLng p) => _c.latLngToScreenOffset(p);

  @override
  LatLng toLatLng(Offset screen) => _c.screenOffsetToLatLng(screen);
}

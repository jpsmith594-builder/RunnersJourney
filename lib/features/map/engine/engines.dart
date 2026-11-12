import '../../../core/settings.dart';
import 'map_engine.dart';
import 'maplibre_engine.dart';

/// Which map engine draws the journey map.
MapEngine createMapEngine(MapEngineKind kind) => switch (kind) {
      MapEngineKind.maptiler => FlutterMapEngine(),
      MapEngineKind.openFreeMap => MapLibreEngine(),
    };

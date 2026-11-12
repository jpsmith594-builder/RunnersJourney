import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How distances and paces are shown.
enum DistanceUnit { km, mi }

/// Which map draws the journey screen. MapTiler is the current map;
/// OpenFreeMap is the one being tested (hidden switch on the spike screen).
enum MapEngineKind { maptiler, openFreeMap }

/// Settings kept on this phone: distance units and light/dark appearance.
class AppSettings extends ChangeNotifier {
  DistanceUnit unit = DistanceUnit.km;
  ThemeMode themeMode = ThemeMode.system;

  /// The faint dotted trail joining races on the map. Off unless chosen.
  bool showTrail = false;

  /// Richer, deeper map colours. On unless switched off.
  bool vividMap = true;

  /// The map engine under the journey screen. Defaults to MapTiler.
  MapEngineKind mapEngine = MapEngineKind.maptiler;

  bool get miles => unit == DistanceUnit.mi;

  /// Reads the saved choices. Without storage the defaults are used.
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      unit = p.getString('unit') == 'mi' ? DistanceUnit.mi : DistanceUnit.km;
      showTrail = p.getBool('trail') ?? false;
      vividMap = p.getBool('vivid') ?? true;
      mapEngine = p.getString('map_engine') == 'openfreemap'
          ? MapEngineKind.openFreeMap
          : MapEngineKind.maptiler;
      themeMode = switch (p.getString('theme')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      // Defaults are fine.
    }
    notifyListeners();
  }

  Future<void> setUnit(DistanceUnit u) async {
    unit = u;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('unit', u == DistanceUnit.mi ? 'mi' : 'km');
    } catch (_) {}
  }

  Future<void> setShowTrail(bool on) async {
    showTrail = on;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('trail', on);
    } catch (_) {}
  }

  Future<void> setVividMap(bool on) async {
    vividMap = on;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('vivid', on);
    } catch (_) {}
  }

  Future<void> setMapEngine(MapEngineKind k) async {
    mapEngine = k;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          'map_engine', k == MapEngineKind.openFreeMap ? 'openfreemap' : 'maptiler');
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('theme', switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      });
    } catch (_) {}
  }

  /// Whether the welcome tour has been shown on this phone.
  Future<bool> tourSeen() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool('tour_seen') ?? false;
    } catch (_) {
      return true; // Never nag when storage is unavailable.
    }
  }

  Future<void> markTourSeen() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('tour_seen', true);
    } catch (_) {}
  }
}

/// The one settings object used across the app.
final AppSettings settings = AppSettings();

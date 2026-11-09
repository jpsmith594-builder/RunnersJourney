import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How distances and paces are shown.
enum DistanceUnit { km, mi }

/// Settings kept on this phone: distance units and light/dark appearance.
class AppSettings extends ChangeNotifier {
  DistanceUnit unit = DistanceUnit.km;
  ThemeMode themeMode = ThemeMode.system;

  /// The faint dotted trail joining races on the map. Off unless chosen.
  bool showTrail = false;

  bool get miles => unit == DistanceUnit.mi;

  /// Reads the saved choices. Without storage the defaults are used.
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      unit = p.getString('unit') == 'mi' ? DistanceUnit.mi : DistanceUnit.km;
      showTrail = p.getBool('trail') ?? false;
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

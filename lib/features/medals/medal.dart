import 'package:flutter/material.dart';

/// The metal of the ring around a medal on the wall.
enum MedalMetal { gold, silver, bronze, titanium }

/// The colour of the ribbon a medal hangs from.
enum MedalRibbon { blue, green, red, purple, orange, yellow, pink, black }

extension MedalMetalX on MedalMetal {
  String get label => switch (this) {
        MedalMetal.gold => 'Gold',
        MedalMetal.silver => 'Silver',
        MedalMetal.bronze => 'Bronze',
        MedalMetal.titanium => 'Titanium',
      };

  /// Light, mid and dark tones for the ring.
  List<Color> get rim => switch (this) {
        MedalMetal.gold => const [
            Color(0xFFFBE7A0),
            Color(0xFFD9A73A),
            Color(0xFF8F6416)
          ],
        MedalMetal.silver => const [
            Color(0xFFF6F8FB),
            Color(0xFFB4BCC8),
            Color(0xFF6C7583)
          ],
        MedalMetal.bronze => const [
            Color(0xFFF0C192),
            Color(0xFFC0803F),
            Color(0xFF78431B)
          ],
        MedalMetal.titanium => const [
            Color(0xFFDFE5EC),
            Color(0xFF8E99A7),
            Color(0xFF4C5662)
          ],
      };
}

extension MedalRibbonX on MedalRibbon {
  String get label => switch (this) {
        MedalRibbon.blue => 'Blue',
        MedalRibbon.green => 'Green',
        MedalRibbon.red => 'Red',
        MedalRibbon.purple => 'Purple',
        MedalRibbon.orange => 'Orange',
        MedalRibbon.yellow => 'Yellow',
        MedalRibbon.pink => 'Pink',
        MedalRibbon.black => 'Black',
      };

  Color get color => switch (this) {
        MedalRibbon.blue => const Color(0xFF0B3D91),
        MedalRibbon.green => const Color(0xFF1B7F5C),
        MedalRibbon.red => const Color(0xFFC0392B),
        MedalRibbon.purple => const Color(0xFF5B2D8A),
        MedalRibbon.orange => const Color(0xFFD68910),
        MedalRibbon.yellow => const Color(0xFFE7B416),
        MedalRibbon.pink => const Color(0xFFD6336C),
        MedalRibbon.black => const Color(0xFF1A1A1F),
      };

  /// The centre stripe of the ribbon.
  Color get stripe => switch (this) {
        MedalRibbon.blue => const Color(0xFFFFD54A),
        MedalRibbon.yellow => const Color(0xFF1A1A1F),
        MedalRibbon.black => const Color(0xFFFFD54A),
        _ => Colors.white,
      };
}

MedalMetal metalFrom(String? s) => MedalMetal.values
    .firstWhere((m) => m.name == s, orElse: () => MedalMetal.gold);

MedalRibbon ribbonFrom(String? s) => MedalRibbon.values
    .firstWhere((r) => r.name == s, orElse: () => MedalRibbon.blue);

/// The metal that matches a race's gold/silver/bronze medal, if it has one.
MedalMetal? metalForRaceMedal(String? raceMedal) {
  for (final m in MedalMetal.values) {
    if (m.name == raceMedal) return m;
  }
  return null;
}

/// One medal on the wall. [url] is a short-lived signed link to the picture.
class Medal {
  final String id;
  final String? raceId;
  final String storagePath;
  final String url;
  final MedalMetal metal;
  final MedalRibbon ribbon;
  final DateTime createdAt;

  const Medal({
    required this.id,
    required this.raceId,
    required this.storagePath,
    required this.url,
    required this.metal,
    required this.ribbon,
    required this.createdAt,
  });
}

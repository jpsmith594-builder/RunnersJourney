import 'package:flutter/material.dart';

import 'season.dart';

/// Colours and decoration settings for each season's jungle.
class SeasonTheme {
  final Season season;
  final String label;
  final IconData icon;
  final Color skyTop;
  final Color skyBottom;
  final Color canopyA;
  final Color canopyB;
  final Color pathDone;
  final Color pathPlanned;
  final Color particle;
  final int particleCount;

  const SeasonTheme({
    required this.season,
    required this.label,
    required this.icon,
    required this.skyTop,
    required this.skyBottom,
    required this.canopyA,
    required this.canopyB,
    required this.pathDone,
    required this.pathPlanned,
    required this.particle,
    required this.particleCount,
  });
}

SeasonTheme themeFor(Season s) {
  switch (s) {
    case Season.spring:
      return const SeasonTheme(
        season: Season.spring,
        label: 'Spring',
        icon: Icons.local_florist,
        skyTop: Color(0xFFBFE3F5),
        skyBottom: Color(0xFFE6F4D7),
        canopyA: Color(0xFF5FAE4B),
        canopyB: Color(0xFF8FCB70),
        pathDone: Color(0xFFC58B3A),
        pathPlanned: Color(0xFF6B5B4B),
        particle: Color(0xFFF6B8D0),
        particleCount: 60,
      );
    case Season.summer:
      return const SeasonTheme(
        season: Season.summer,
        label: 'Summer',
        icon: Icons.wb_sunny,
        skyTop: Color(0xFF7CC8E8),
        skyBottom: Color(0xFFCDE9A8),
        canopyA: Color(0xFF1B7A3A),
        canopyB: Color(0xFF2FA04F),
        pathDone: Color(0xFFC58B3A),
        pathPlanned: Color(0xFF5E5040),
        particle: Color(0xFFFFF3A0),
        particleCount: 40,
      );
    case Season.autumn:
      return const SeasonTheme(
        season: Season.autumn,
        label: 'Autumn',
        icon: Icons.eco,
        skyTop: Color(0xFFF3C98B),
        skyBottom: Color(0xFFF1E0B8),
        canopyA: Color(0xFFB5651D),
        canopyB: Color(0xFFD98F2B),
        pathDone: Color(0xFF9C6B30),
        pathPlanned: Color(0xFF6B5B4B),
        particle: Color(0xFFE07A2F),
        particleCount: 70,
      );
    case Season.winter:
      return const SeasonTheme(
        season: Season.winter,
        label: 'Winter',
        icon: Icons.ac_unit,
        skyTop: Color(0xFFB7C9DA),
        skyBottom: Color(0xFFE8EEF3),
        canopyA: Color(0xFF3F6B5A),
        canopyB: Color(0xFF6E9A88),
        pathDone: Color(0xFFA77B45),
        pathPlanned: Color(0xFF55606A),
        particle: Color(0xFFFFFFFF),
        particleCount: 80,
      );
  }
}

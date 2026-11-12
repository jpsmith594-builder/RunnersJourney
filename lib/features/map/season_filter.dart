import 'package:flutter/material.dart';

import '../../core/season.dart';

const double vividSaturation = 1.5;
const double vividContrast = 1.1;
const double vividDarken = 6; // out of 255

/// A gentle colour grade applied to the map artwork so it follows the season.
ColorFilter seasonFilter(Season s, {bool vivid = false}) =>
    ColorFilter.matrix(seasonMatrix(s, vivid: vivid));

/// The 4 x 5 colour matrix behind [seasonFilter] (offsets are on a 0 to 255
/// scale). Also used to recolour vector map styles.
List<double> seasonMatrix(Season s, {bool vivid = false}) {
  final double sat;
  final double r, g, b;
  switch (s) {
    case Season.spring:
      sat = 1.08;
      r = 1.0;
      g = 1.03;
      b = 1.0;
    case Season.summer:
      sat = 1.04;
      r = 1.0;
      g = 1.0;
      b = 1.0;
    case Season.autumn:
      sat = 0.95;
      r = 1.07;
      g = 1.0;
      b = 0.86;
    case Season.winter:
      sat = 0.65;
      r = 0.93;
      g = 0.99;
      b = 1.08;
  }
  // Vivid: richer saturation, a touch more contrast and slightly deeper tones.
  final satV = vivid ? sat * vividSaturation : sat;
  final c = vivid ? vividContrast : 1.0;
  final off = vivid ? 255 * (0.5 - 0.5 * c) - vividDarken : 0.0;
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final inv = 1 - satV;
  return <double>[
    c * r * (lr * inv + satV), c * r * (lg * inv), c * r * (lb * inv), 0, off,
    c * g * (lr * inv), c * g * (lg * inv + satV), c * g * (lb * inv), 0, off,
    c * b * (lr * inv), c * b * (lg * inv), c * b * (lb * inv + satV), 0, off,
    0, 0, 0, 1, 0,
  ];
}

String seasonLabel(Season s) {
  switch (s) {
    case Season.spring:
      return 'Spring';
    case Season.summer:
      return 'Summer';
    case Season.autumn:
      return 'Autumn';
    case Season.winter:
      return 'Winter';
  }
}

IconData seasonIcon(Season s) {
  switch (s) {
    case Season.spring:
      return Icons.local_florist;
    case Season.summer:
      return Icons.wb_sunny;
    case Season.autumn:
      return Icons.eco;
    case Season.winter:
      return Icons.ac_unit;
  }
}

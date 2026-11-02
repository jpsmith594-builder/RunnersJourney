import 'package:flutter/material.dart';

import '../../core/season.dart';

/// A gentle colour grade applied to the map artwork so it follows the season.
ColorFilter seasonFilter(Season s) {
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
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final inv = 1 - sat;
  return ColorFilter.matrix(<double>[
    r * (lr * inv + sat), r * (lg * inv), r * (lb * inv), 0, 0,
    g * (lr * inv), g * (lg * inv + sat), g * (lb * inv), 0, 0,
    b * (lr * inv), b * (lg * inv), b * (lb * inv + sat), 0, 0,
    0, 0, 0, 1, 0,
  ]);
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

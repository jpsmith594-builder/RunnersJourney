import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

enum PinShape { teardrop, dot, pill }

/// One marker to draw on the map itself (not as a Flutter widget), so it moves
/// with the map without lagging.
class NativePin {
  /// A race id, "bucket:Town", "cluster:3", or "label:..." / "dot:..." for
  /// markers that cannot be tapped.
  final String id;
  final LatLng pos;
  final PinShape shape;

  /// Size in logical points.
  final double w, h;
  final Color fill, ink;
  final String text;
  final double fontSize;
  final IconData? icon;
  final bool selected;

  const NativePin({
    required this.id,
    required this.pos,
    required this.shape,
    required this.w,
    required this.h,
    required this.fill,
    required this.ink,
    this.text = '',
    this.fontSize = 15,
    this.icon,
    this.selected = false,
  });

  /// Pins that look the same share one picture.
  String get imageKey =>
      '${shape.name}|$w|$h|${fill.toARGB32()}|${ink.toARGB32()}|$text|$fontSize|${icon?.codePoint}';
}

/// One leg of the trail between two races.
class NativeLeg {
  final LatLng a, b;
  final bool planned;
  final double alpha;
  final double width;
  const NativeLeg(this.a, this.b,
      {required this.planned, required this.alpha, required this.width});
}

/// A small town marker with its name.
class NativeTown {
  final String key, name;
  final int tier;
  final LatLng pos;
  const NativeTown(this.key, this.name, this.tier, this.pos);
}

/// Everything the journey screen wants drawn on the map itself.
class MapOverlayData {
  final List<NativePin> pins;
  final List<NativeLeg> legs;
  final List<NativeTown> towns;
  const MapOverlayData(
      {required this.pins, required this.legs, required this.towns});
}

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'map_engine.dart';

/// A map camera worked out in plain Dart (Web Mercator, north up, no tilt), so
/// pins and the trail can be placed instantly without asking the map engine.
/// [zoom] is in the app's units (256 px tiles).
class MercatorCam implements MapCam {
  @override
  final LatLng center;
  @override
  final double zoom;
  final Size size;

  const MercatorCam(this.center, this.zoom, this.size);

  double get _world => 256.0 * math.pow(2, zoom);

  static double _x(double lng) => (lng + 180) / 360;

  static double _y(double lat) {
    final l = lat.clamp(-85.0511287798, 85.0511287798).toDouble();
    final s = math.sin(l * math.pi / 180);
    return 0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi);
  }

  @override
  Offset toScreen(LatLng p) {
    var dx = _x(p.longitude) - _x(center.longitude);
    // Use the copy of the world nearest the centre.
    if (dx > 0.5) {
      dx -= 1;
    } else if (dx < -0.5) {
      dx += 1;
    }
    final dy = _y(p.latitude) - _y(center.latitude);
    return Offset(size.width / 2 + dx * _world, size.height / 2 + dy * _world);
  }

  @override
  LatLng toLatLng(Offset o) {
    final x = _x(center.longitude) + (o.dx - size.width / 2) / _world;
    final y = _y(center.latitude) + (o.dy - size.height / 2) / _world;
    final lng = (((x * 360 - 180) + 180) % 360 + 360) % 360 - 180;
    final lat = math.atan(_sinh(2 * math.pi * (0.5 - y))) * 180 / math.pi;
    return LatLng(lat, lng);
  }

  static double _sinh(double v) => (math.exp(v) - math.exp(-v)) / 2;
}

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:runners_journey/features/map/engine/mercator.dart';

void main() {
  const size = Size(400, 700);
  const centre = LatLng(-29.0, 24.5);

  test('the camera centre is the middle of the screen', () {
    const cam = MercatorCam(centre, 5, size);
    final o = cam.toScreen(centre);
    expect(o.dx, closeTo(200, 1e-6));
    expect(o.dy, closeTo(350, 1e-6));
  });

  test('one degree of longitude is world width over 360 pixels', () {
    const zoom = 6.0;
    const cam = MercatorCam(centre, zoom, size);
    final o = cam.toScreen(const LatLng(-29.0, 25.5));
    expect(o.dx - 200, closeTo(256 * math.pow(2, zoom) / 360, 1e-6));
    expect(o.dy, closeTo(350, 1e-6));
  });

  test('north is up and east is right', () {
    const cam = MercatorCam(centre, 5, size);
    final n = cam.toScreen(const LatLng(-28.0, 24.5));
    final e = cam.toScreen(const LatLng(-29.0, 25.5));
    expect(n.dy, lessThan(350));
    expect(e.dx, greaterThan(200));
  });

  test('screen positions convert back to the same place', () {
    const cam = MercatorCam(centre, 7.3, size);
    for (final p in const [
      LatLng(-33.9, 18.4),
      LatLng(-26.2, 28.0),
      LatLng(-30.5, 22.0),
    ]) {
      final back = cam.toLatLng(cam.toScreen(p));
      expect(back.latitude, closeTo(p.latitude, 1e-6));
      expect(back.longitude, closeTo(p.longitude, 1e-6));
    }
  });

  test('uses the nearest copy of the world across the date line', () {
    const cam = MercatorCam(LatLng(0, 179), 3, size);
    final o = cam.toScreen(const LatLng(0, -179));
    // Two degrees east of the centre, not 358 west.
    expect(o.dx - 200, closeTo(256 * 8 * 2 / 360, 1e-6));
  });
}

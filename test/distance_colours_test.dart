import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/map/distance_colours.dart';

void main() {
  test('common race distances land in the right colour group', () {
    expect(distanceBand(5), DistanceBand.fiveK);
    expect(distanceBand(10), DistanceBand.tenK);
    expect(distanceBand(21.1), DistanceBand.half);
    expect(distanceBand(42.2), DistanceBand.full);
    expect(distanceBand(56), DistanceBand.ultra);
    expect(distanceBand(89), DistanceBand.ultra);
  });

  test('in-between distances fall into the nearest group below', () {
    expect(distanceBand(7.9), DistanceBand.fiveK);
    expect(distanceBand(8), DistanceBand.tenK);
    expect(distanceBand(14.9), DistanceBand.tenK);
    expect(distanceBand(15), DistanceBand.half);
    expect(distanceBand(16.1), DistanceBand.half);
    expect(distanceBand(29.9), DistanceBand.half);
    expect(distanceBand(30), DistanceBand.full);
    expect(distanceBand(43), DistanceBand.full);
    expect(distanceBand(43.1), DistanceBand.ultra);
  });

  test('unknown or zero distance has no colour', () {
    expect(distanceBand(null), isNull);
    expect(distanceBand(0), isNull);
    expect(distanceColour(null), isNull);
  });

  test('every group has its own colour', () {
    final colours = DistanceBand.values.map((b) => b.color.toARGB32()).toSet();
    expect(colours.length, DistanceBand.values.length);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/journey/trail_layout.dart';
import 'package:runners_journey/features/races/race.dart';

Race _race(int i, RaceStatus s) => Race(
      id: 'r$i',
      name: 'Race $i',
      date: DateTime(2026, 1 + i, 1),
      status: s,
    );

void main() {
  test('trail runs from bottom (oldest) upwards and stays inside the width', () {
    final races = [
      _race(0, RaceStatus.completed),
      _race(1, RaceStatus.completed),
      _race(2, RaceStatus.planned),
    ];
    final l = layoutTrail(races, 400, 600);
    expect(l.points.length, 3);
    expect(l.points[0].pos.dy, greaterThan(l.points[1].pos.dy));
    expect(l.points[1].pos.dy, greaterThan(l.points[2].pos.dy));
    expect(l.start.dy, greaterThan(l.points[0].pos.dy));
    for (final p in l.points) {
      expect(p.pos.dx, inInclusiveRange(0, 400));
    }
    expect(l.points[0].passed, isTrue);
    expect(l.points[2].passed, isFalse);
  });

  test('empty list still gives a screen-sized trail', () {
    final l = layoutTrail([], 400, 700);
    expect(l.points, isEmpty);
    expect(l.height, 700);
  });
}

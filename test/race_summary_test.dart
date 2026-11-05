import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/races/race.dart';
import 'package:runners_journey/features/races/race_list_screen.dart';

void main() {
  test('summary tiles', () {
    final now = DateTime(2026, 11, 5);
    final s = RaceSummary.from([
      Race(
          name: 'A',
          date: DateTime(2026, 3, 1),
          status: RaceStatus.completed,
          distanceKm: 10,
          finishTimeSeconds: 3000),
      Race(
          name: 'B',
          date: DateTime(2025, 3, 1),
          status: RaceStatus.completed,
          distanceKm: 21.1,
          finishTimeSeconds: 6000),
      Race(name: 'C', date: DateTime(2026, 11, 20), status: RaceStatus.planned),
      Race(name: 'D', date: DateTime(2026, 12, 20), status: RaceStatus.planned),
      Race(name: 'E', date: DateTime(2026, 5, 1), status: RaceStatus.dnf),
    ], now);
    expect(s.finished, 2);
    expect(s.thisYear, 1);
    expect(s.km, closeTo(31.1, 0.001));
    expect(s.kmThisYear, 10);
    expect(s.seconds, 9000);
    expect(s.nextPlanned?.race.name, 'C');
    expect(s.nextPlanned?.days, 15);
  });
}

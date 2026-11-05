import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/races/race.dart';
import 'package:runners_journey/features/stats/charts_screen.dart';

Race _r(int y, double km, int secs,
        {RaceStatus status = RaceStatus.completed, String? medal}) =>
    Race(
        name: 'r$y',
        date: DateTime(y, 5, 1),
        status: status,
        distanceKm: km,
        finishTimeSeconds: secs,
        medal: medal);

void main() {
  test('chart numbers per year', () {
    final s = ChartStats.from([
      _r(2025, 10, 3000, medal: 'gold'),
      _r(2025, 21.1, 6330),
      _r(2026, 10, 2900, medal: 'bronze'),
      _r(2026, 8, 2000, status: RaceStatus.planned, medal: 'gold'),
      _r(2026, 5, 1000, status: RaceStatus.planned),
    ]);
    expect(s.racesPerYear, {2025: 2, 2026: 1});
    expect(s.kmPerYear[2025], closeTo(31.1, 0.001));
    expect(s.paceSecPerKm[2026], closeTo(290, 0.001));
    expect(s.paceSecPerKm[2025], closeTo(9330 / 31.1, 0.001));
    expect(s.medals, {'gold': 1, 'silver': 0, 'bronze': 1}); // planned races do not count
  });

  test('pace label and last years', () {
    expect(paceLabel(305), '5:05');
    final m = {for (var y = 2010; y < 2020; y++) y: y};
    final last = ChartStats.lastYears(m);
    expect(last.length, 8);
    expect(last.first.key, 2012);
    expect(last.last.key, 2019);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/home/on_this_day_banner.dart';
import 'package:runners_journey/features/races/race.dart';

Race r(String id, DateTime d, [RaceStatus s = RaceStatus.completed]) =>
    Race(id: id, name: id, date: d, status: s);

void main() {
  final races = [
    r('two', DateTime(2024, 11, 7)),
    r('one', DateTime(2025, 11, 7)),
    r('today', DateTime(2026, 11, 7)),
    r('other', DateTime(2025, 11, 8)),
    r('dnf', DateTime(2023, 11, 7), RaceStatus.dnf),
    r('plan', DateTime(2027, 11, 7), RaceStatus.planned),
  ];

  test('same day in earlier years, most recent first', () {
    final m = onThisDay(races, DateTime(2026, 11, 7));
    expect(m.map((e) => e.race.id), ['one', 'two']);
    expect(m.map((e) => e.yearsAgo), [1, 2]);
  });

  test('nothing on a day without memories', () {
    expect(onThisDay(races, DateTime(2026, 5, 5)), isEmpty);
  });

  test('a 29 February race shows on 28 February in other years', () {
    final leap = [r('leap', DateTime(2024, 2, 29))];
    expect(onThisDay(leap, DateTime(2026, 2, 28)).length, 1);
    expect(onThisDay(leap, DateTime(2028, 2, 28)), isEmpty);
    expect(onThisDay(leap, DateTime(2028, 2, 29)).length, 1);
  });
}

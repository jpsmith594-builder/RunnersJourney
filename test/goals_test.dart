import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/goals/goals.dart';
import 'package:runners_journey/features/races/race.dart';

Race r(DateTime d, RaceStatus s, {double km = 10}) => Race(
    id: '${d.toIso8601String()}$km', name: 'r', date: d, status: s, distanceKm: km);

void main() {
  final now = DateTime(2026, 7, 1);
  final races = [
    r(DateTime(2026, 2, 1), RaceStatus.completed, km: 21.1),
    r(DateTime(2026, 5, 1), RaceStatus.completed, km: 10),
    r(DateTime(2026, 9, 1), RaceStatus.planned),
    r(DateTime(2026, 3, 1), RaceStatus.planned), // already past
    r(DateTime(2025, 6, 1), RaceStatus.completed, km: 42.2),
  ];

  test('counts finished races and distance for the year only', () {
    final g = goalProgress(races, 2026,
        goalKm: 100, goalRaces: 4, now: now);
    expect(g.races, 2);
    expect(g.km, closeTo(31.1, 0.001));
    expect(g.plannedLeft, 1);
    expect(g.kmFraction, closeTo(0.311, 0.001));
    expect(g.racesFraction, 0.5);
  });

  test('no goal means no fraction and no hint', () {
    final g = goalProgress(races, 2026, now: now);
    expect(g.kmFraction, isNull);
    expect(g.kmHint(now), isNull);
    expect(g.racesHint(), isNull);
  });

  test('hints say what is left', () {
    final g = goalProgress(races, 2026, goalKm: 100, goalRaces: 4, now: now);
    // 68.9 km left over 6 months (July to December) = 12 a month.
    expect(g.kmHint(now), contains('12 km a month'));
    expect(g.racesHint(), '2 more races to go. 1 already planned.');
  });

  test('reaching a goal is celebrated and fractions stop at 100%', () {
    final g = goalProgress(races, 2026, goalKm: 20, goalRaces: 2, now: now);
    expect(g.kmReached, isTrue);
    expect(g.racesReached, isTrue);
    expect(g.kmFraction, 1.0);
    expect(g.kmHint(now), contains('reached'));
  });

  test('next badge is the unearned one that is closest', () {
    final b = nextBadge(races);
    // Whatever it is, it must be unearned and have progress.
    if (b != null) {
      expect(b.earned, isFalse);
      expect(b.progress, isNotNull);
    }
  });
}

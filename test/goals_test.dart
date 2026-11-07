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

  group('goals by year', () {
    final goals = {
      2025: const YearGoal(2025, km: 300, races: 8),
      2026: const YearGoal(2026, races: 12),
    };

    test('latest earlier goal', () {
      expect(latestGoalBefore(goals, 2027)?.year, 2026);
      expect(latestGoalBefore(goals, 2026)?.year, 2025);
      expect(latestGoalBefore(goals, 2025), isNull);
    });

    test('new year prompt only when this year has no goal yet', () {
      expect(needsNewYearPrompt(goals, DateTime(2027, 1, 2)), isTrue);
      expect(needsNewYearPrompt(goals, DateTime(2026, 6, 1)), isFalse);
      expect(needsNewYearPrompt({}, DateTime(2027, 1, 2)), isFalse);
      // An empty goal for the new year still counts as "not set".
      expect(
          needsNewYearPrompt(
              {...goals, 2027: const YearGoal(2027)}, DateTime(2027, 1, 2)),
          isTrue);
    });

    test('past year result and achievement', () {
      final done = [
        r(DateTime(2025, 2, 1), RaceStatus.completed, km: 21.1),
        r(DateTime(2025, 5, 1), RaceStatus.completed, km: 10),
      ];
      final g = goalProgress(done, 2025, goalKm: 30, goalRaces: 2);
      expect(yearResult(g), '2 / 2 races, 31.1 / 30 km');
      expect(yearAchieved(g), isTrue);
      final miss = goalProgress(done, 2025, goalKm: 300, goalRaces: 2);
      expect(yearAchieved(miss), isFalse);
      expect(yearAchieved(goalProgress(done, 2025)), isFalse);
    });
  });
}

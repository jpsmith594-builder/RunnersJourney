import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/home/upcoming_banner.dart';
import 'package:runners_journey/features/races/race.dart';
import 'package:runners_journey/features/stats/badges.dart';
import 'package:runners_journey/features/stats/year_review.dart';

Race race(String name, DateTime date,
        {RaceStatus status = RaceStatus.completed,
        double? km,
        int? secs,
        String? town}) =>
    Race(
        name: name,
        date: date,
        status: status,
        distanceKm: km,
        finishTimeSeconds: secs,
        locationName: town);

void main() {
  group('badges', () {
    bool earned(List<BadgeResult> l, String id) =>
        l.firstWhere((b) => b.badge.id == id).earned;

    test('nothing earned without races', () {
      expect(computeBadges([]).where((b) => b.earned), isEmpty);
    });

    test('distance, time and place badges', () {
      final l = computeBadges([
        race('A', DateTime(2026, 1, 1), km: 10, secs: 3000, town: 'Cape Town'),
        race('Comrades Marathon', DateTime(2026, 6, 1),
            km: 88, secs: 40000, town: 'Durban'),
        race('P', DateTime(2026, 7, 1),
            status: RaceStatus.planned, km: 42.2, town: 'George'),
      ]);
      expect(earned(l, 'first'), isTrue);
      expect(earned(l, 'first10k'), isTrue);
      expect(earned(l, 'sub60'), isTrue);
      expect(earned(l, 'ultra'), isTrue);
      expect(earned(l, 'comrades'), isTrue);
      expect(earned(l, 'firstmarathon'), isFalse); // planned does not count
      expect(earned(l, 'prov3'), isFalse);
      expect(l.firstWhere((b) => b.badge.id == 'races5').progress, '2 / 5');
    });
  });

  group('year review', () {
    test('summarises one year only', () {
      final races = [
        race('A', DateTime(2025, 3, 1), km: 10, secs: 3000),
        race('B', DateTime(2026, 3, 1), km: 21.1, secs: 6000, town: 'Cape Town'),
        race('C', DateTime(2026, 3, 20), km: 10, secs: 2900, town: 'Paarl'),
      ];
      expect(yearsWithRaces(races), [2026, 2025]);
      final s = summarize(races, 2026);
      expect(s.races, 2);
      expect(s.km, closeTo(31.1, 0.001));
      expect(s.towns, 2);
      expect(s.busiestMonth, 3);
      expect(s.pbs['10K'], 2900);
      expect(s.longest!.name, 'B');
    });
  });

  group('upcoming banner', () {
    final now = DateTime(2026, 6, 1);
    test('picks the nearest planned race within 60 days', () {
      final n = UpcomingBanner.nextRace([
        race('Far', DateTime(2026, 9, 1), status: RaceStatus.planned),
        race('Soon', DateTime(2026, 6, 11), status: RaceStatus.planned),
        race('Done', DateTime(2026, 6, 5)),
      ], now);
      expect(n!.race.name, 'Soon');
      expect(n.days, 10);
    });
    test('none when nothing is close', () {
      expect(
          UpcomingBanner.nextRace(
              [race('Far', DateTime(2026, 9, 1), status: RaceStatus.planned)],
              now),
          isNull);
    });
  });
}

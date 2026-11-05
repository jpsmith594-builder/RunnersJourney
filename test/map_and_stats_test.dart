import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/map/map_geometry.dart';
import 'package:runners_journey/features/map/places.dart';
import 'package:runners_journey/features/profile/runner_stats.dart';
import 'package:runners_journey/features/races/race.dart';

Race _race(
  String name, {
  String? town,
  RaceStatus status = RaceStatus.completed,
  double? km,
  int? seconds,
}) =>
    Race(
      id: name,
      name: name,
      date: DateTime(2026, 3, 1),
      status: status,
      distanceKm: km,
      finishTimeSeconds: seconds,
      locationName: town,
    );

void main() {
  suburbTests();
  group('places', () {
    test('names are unique and positions are inside South Africa', () {
      final names = <String>{};
      for (final p in kPlaces) {
        expect(names.add(p.name.toLowerCase()), isTrue, reason: p.name);
        expect(p.lng, inInclusiveRange(14, 36), reason: p.name);
        expect(p.lat, inInclusiveRange(-36, -21), reason: p.name);
        expect(p.tier, inInclusiveRange(1, 5), reason: p.name);
      }
    });

    test('lookup is case-insensitive and search ranks prefixes first', () {
      expect(placeByName(' cape town ')?.name, 'Cape Town');
      expect(placeByName('Nowhereville'), isNull);
      expect(searchPlaces('stel').first.name, 'Stellenbosch');
      expect(searchPlaces('').every((p) => p.tier == 1), isTrue);
    });
  });

  group('map grouping', () {
    test('groups races by town and keeps unknown towns aside', () {
      final r = groupRaces([
        _race('a', town: 'Cape Town'),
        _race('b', town: 'cape town'),
        _race('c', town: 'Durban'),
        _race('d', town: 'Atlantis Fantasy'),
        _race('e'),
      ]);
      expect(r.groups.length, 2);
      expect(r.unplaced.length, 2);
      final ct = r.groups.firstWhere((g) => g.place.name == 'Cape Town');
      expect(ct.races.length, 2);
    });

    test('nearby towns merge into one numbered cluster when zoomed out', () {
      final r = groupRaces([
        _race('a', town: 'Cape Town'),
        _race('b', town: 'Stellenbosch'),
        _race('c', town: 'Durban'),
      ]);
      // Zoomed out: everything within 10 px of each other.
      var clusters = clusterGroups(r.groups, (p) => const Offset(10, 10), 28);
      expect(clusters.length, 1);
      expect(clusters.first.count, 3);

      // Zoomed in: towns far apart on screen stay separate.
      clusters = clusterGroups(
          r.groups, (p) => Offset(p.lng * 300, -p.lat * 300), 28);
      expect(clusters.length, 3);
    });

    test('fan offsets spread pins evenly on a ring', () {
      final o = fanOffsets(4);
      expect(o.length, 4);
      final radius = o.first.distance;
      for (final p in o) {
        expect(p.distance, closeTo(radius, 0.001));
      }
      expect(o.toSet().length, 4);
      expect(fanOffsets(0), isEmpty);
    });
  });

  group('runner stats', () {
    test('counts only completed races and finds personal bests', () {
      final s = computeStats([
        _race('5k a', town: 'Paarl', km: 5, seconds: 1500),
        _race('5k b', town: 'Paarl', km: 5, seconds: 1420),
        _race('half', town: 'Durban', km: 21.1, seconds: 6600),
        _race('dnf', town: 'Durban', km: 10, status: RaceStatus.dnf),
        _race('plan', town: 'Knysna', km: 42.2, status: RaceStatus.planned),
      ]);
      expect(s.completed, 3);
      expect(s.totalKm, closeTo(31.1, 0.001));
      expect(s.towns, 2);
      expect(s.pb5k, 1420);
      expect(s.pb21k, 6600);
      expect(s.pb10k, isNull);
      expect(s.pb42k, isNull);
    });

    test('rating and tier grow with experience and are capped', () {
      expect(computeStats([]).rating, 0);
      expect(computeStats([]).tier, CardTier.novice);

      const tiers = [
        (79, CardTier.novice),
        (80, CardTier.rookie),
        (180, CardTier.club),
        (300, CardTier.competitor),
        (450, CardTier.veteran),
        (650, CardTier.master),
        (850, CardTier.elite),
      ];
      for (final (rating, tier) in tiers) {
        final s = _withRating(rating);
        expect(s.rating, rating);
        expect(s.tier, tier, reason: '$rating');
      }
    });

    test('each part is capped', () {
      const s = RunnerStats(
          completed: 500,
          totalKm: 99999,
          towns: 500,
          golds: 500,
          countries: 500,
          improvement: 9999);
      expect(s.rating, 1000);
      expect(s.pointsToNext, isNull);
      expect(_withRating(100).pointsToNext, 80);
    });

    test('a busy first year does not reach Elite', () {
      final races = [
        for (var i = 0; i < 30; i++)
          Race(
            id: '$i',
            name: 'r$i',
            date: DateTime(2025, 1 + i % 12, 1 + i % 28),
            status: RaceStatus.completed,
            distanceKm: 10.0,
            finishTimeSeconds: 3600 - i * 20,
            locationName: 'Town ${i % 15}',
            country: i % 3 == 0 ? 'South Africa' : (i % 3 == 1 ? 'Kenya' : 'Namibia'),
            medal: i < 10 ? 'gold' : null,
          ),
      ];
      final s = computeStats(races);
      expect(s.rating, lessThan(650));
      expect(s.tier.index, lessThan(CardTier.master.index));
    });

    test('improvement rewards getting faster than your own past', () {
      Race r(int year, int seconds) => Race(
            id: '$year-$seconds',
            name: 'r',
            date: DateTime(year, 5, 1),
            status: RaceStatus.completed,
            distanceKm: 10.0,
            finishTimeSeconds: seconds,
          );
      // One 10K only: nothing to compare with.
      expect(computeStats([r(2023, 3600)]).improvement, 0);
      // 20% faster in a later season: 40 for the gain + 10 for the new season.
      expect(computeStats([r(2023, 3600), r(2024, 2880)]).improvement, 50);
      // Getting slower earns nothing.
      expect(computeStats([r(2023, 3000), r(2024, 3300)]).improvement, 0);
    });
  });
}


void suburbTests() {
  group('cape town suburbs', () {
    test('sit near Cape Town at deep tiers', () {
      final ct = placeByName('Cape Town')!;
      final sub = kPlaces.where((p) => p.tier >= 4).toList();
      expect(sub.length, greaterThan(20));
      for (final p in sub) {
        expect((p.lng - ct.lng).abs(), lessThan(0.7), reason: p.name);
        expect((p.lat - ct.lat).abs(), lessThan(0.6), reason: p.name);
      }
    });
  });
}

RunnerStats _withRating(int rating) {
  // Improvement alone can reach 250, so use medals/towns/etc. in steps.
  var left = rating;
  int take(int per, int cap) {
    final n = (left ~/ per).clamp(0, cap ~/ per);
    left -= n * per;
    return n;
  }

  final completed = take(6, 250);
  final towns = take(4, 100);
  final countries = take(10, 80);
  final golds = take(10, 120);
  final km = take(1, 200) * 8.0;
  final improvement = left.clamp(0, 250);
  return RunnerStats(
    completed: completed,
    totalKm: km,
    towns: towns,
    countries: countries,
    golds: golds,
    improvement: improvement,
  );
}

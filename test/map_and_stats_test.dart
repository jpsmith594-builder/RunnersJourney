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
  group('places', () {
    test('names are unique and positions are inside the artwork', () {
      final names = <String>{};
      for (final p in kPlaces) {
        expect(names.add(p.name.toLowerCase()), isTrue, reason: p.name);
        expect(p.fx, inInclusiveRange(0, 1), reason: p.name);
        expect(p.fy, inInclusiveRange(0, 1), reason: p.name);
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
          r.groups, (p) => Offset(p.fx * 5000, p.fy * 3000), 28);
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
      expect(computeStats([]).rating, 45);
      expect(computeStats([]).tier, CardTier.bronze);

      final many = [
        for (var i = 0; i < 40; i++)
          _race('r$i', town: 'Paarl', km: 21.1, seconds: 7000),
      ];
      final s = computeStats(many);
      expect(s.rating, 99);
      expect(s.tier, CardTier.elite);

      expect(const RunnerStats(completed: 7, totalKm: 0, towns: 0).tier,
          CardTier.bronze); // 59
      expect(const RunnerStats(completed: 8, totalKm: 0, towns: 0).tier,
          CardTier.silver); // 61
      expect(const RunnerStats(completed: 15, totalKm: 0, towns: 0).tier,
          CardTier.gold); // 75
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/map/map_geometry.dart';
import 'package:runners_journey/features/map/places.dart';
import 'package:runners_journey/features/races/race.dart';
import 'package:runners_journey/features/stats/badges.dart';

Race _r(String town, double lat, double lng, String region, String country,
        {int day = 1}) =>
    Race(
      name: 'R $town',
      date: DateTime(2026, 1, day),
      status: RaceStatus.completed,
      distanceKm: 10,
      finishTimeSeconds: 3600,
      locationName: town,
      lat: lat,
      lng: lng,
      region: region,
      country: country,
    );

void main() {
  test('geocoding response becomes places and skips streets', () {
    final out = GeoSearch.parseFeatures({
      'features': [
        {
          'text': 'Langebaan',
          'place_type': ['municipal_district'],
          'center': [18.03, -33.09],
          'context': [
            {'id': 'region.1', 'text': 'Western Cape'},
            {'id': 'country.2', 'text': 'South Africa'},
          ],
        },
        {
          'text': 'Main Street',
          'place_type': ['address'],
          'center': [1.0, 2.0],
        },
      ],
    });
    expect(out.length, 1);
    expect(out.first.name, 'Langebaan');
    expect(out.first.lat, -33.09);
    expect(out.first.lng, 18.03);
    expect(out.first.province, 'Western Cape');
    expect(out.first.country, 'South Africa');
  });

  test('a race keeps its own coordinates and country', () {
    final p = placeForRace(_r('Paris', 48.85, 2.35, 'Ile-de-France', 'France'))!;
    expect(p.lat, 48.85);
    expect(p.country, 'France');
    // old races without coordinates still resolve by name
    expect(
        placeForRace(Race(
            name: 'x',
            date: _d,
            status: RaceStatus.completed,
            locationName: 'Cape Town'))!
            .country,
        'South Africa');
  });

  test('same town name in two countries stays separate', () {
    final g = groupRaces([
      _r('Paris', 48.85, 2.35, 'Texas', 'United States'),
      _r('Paris', 48.85, 2.35, 'Ile-de-France', 'France', day: 2),
    ]);
    expect(g.groups.length, 2);
  });

  test('picked place wins while the text still matches', () {
    const picked = Place('Paris', 'Texas', 33.6, -95.5, 3, country: 'United States');
    expect(resolvePlace('paris', picked), picked);
    expect(resolvePlace('Durban', picked)?.name, 'Durban');
    expect(resolvePlace('  ', picked), isNull);
  });

  test('merge drops repeats', () {
    final local = [placeByName('Durban')!];
    final remote = [const Place('Durban', 'KwaZulu-Natal', -29.8, 31.0, 3)];
    expect(mergePlaces(local, remote).length, 1);
  });

  test('country badges', () {
    final l = computeBadges([
      _r('Cape Town', -33.9, 18.4, 'Western Cape', 'South Africa'),
      _r('London', 51.5, -0.1, 'England', 'United Kingdom', day: 2),
    ]);
    bool earned(String id) => l.firstWhere((b) => b.badge.id == id).earned;
    expect(earned('country2'), isTrue);
    expect(earned('country5'), isFalse);
  });
}

final _d = DateTime(2026, 1, 1);

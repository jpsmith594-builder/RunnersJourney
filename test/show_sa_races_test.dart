import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/calendar/show_sa_races.dart';
import 'package:runners_journey/features/races/race.dart';

void main() {
  Race race({String? town, String? country, double? lat, double? lng}) => Race(
      id: 'x',
      name: 'r',
      date: DateTime(2026, 1, 1),
      status: RaceStatus.completed,
      locationName: town,
      country: country,
      lat: lat,
      lng: lng);

  test('shown for a South African phone', () {
    expect(showSouthAfricanRaces(races: [], localeCountry: 'ZA'), isTrue);
    expect(showSouthAfricanRaces(races: [], localeCountry: 'za'), isTrue);
  });

  test('shown for a known South African home town', () {
    expect(showSouthAfricanRaces(races: [], homeTown: 'Cape Town'), isTrue);
  });

  test('shown when there is already a race in South Africa', () {
    expect(
        showSouthAfricanRaces(races: [race(town: 'Cape Town')]), isTrue);
  });

  test('hidden for a runner elsewhere', () {
    expect(showSouthAfricanRaces(races: [], localeCountry: 'DE'), isFalse);
    expect(
        showSouthAfricanRaces(
            races: [
              race(town: 'Berlin', country: 'Germany', lat: 52.5, lng: 13.4)
            ],
            homeTown: 'Berlin',
            localeCountry: 'DE'),
        isFalse);
    expect(showSouthAfricanRaces(races: []), isFalse);
  });
}

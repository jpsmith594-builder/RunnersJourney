import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/album/album_screen.dart';
import 'package:runners_journey/features/races/race.dart';

Race r(String id, int year, RaceStatus s) =>
    Race(id: id, name: id, date: DateTime(year, 6, 1), status: s);

void main() {
  final all = [
    r('b', 2024, RaceStatus.completed),
    r('a', 2023, RaceStatus.completed),
    r('p', 2025, RaceStatus.planned),
    r('c', 2024, RaceStatus.completed),
  ];

  test('finished races only, oldest first', () {
    expect(albumRaces(all).map((e) => e.id), ['a', 'b', 'c']);
  });

  test('year and photo filters', () {
    expect(albumRaces(all, year: 2024).map((e) => e.id), ['b', 'c']);
    expect(
        albumRaces(all, photoRaceIds: {'c'}).map((e) => e.id), ['c']);
  });

  test('no photos at all keeps every race', () {
    expect(albumRaces(all, photoRaceIds: {}).length, 3);
    expect(albumRaces(all, onlyWithPhotos: false, photoRaceIds: {'c'}).length,
        3);
  });
}

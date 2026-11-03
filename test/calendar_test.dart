import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/calendar/race_event.dart';
import 'package:runners_journey/features/map/places.dart';

void main() {
  test('calendar towns exist on the map', () {
    for (final e in kRaceEvents) {
      if (e.town != null) {
        expect(placeByName(e.town), isNotNull, reason: e.name);
      }
    }
  });

  test('search finds races by name and town', () {
    expect(searchEvents('comr').first.name, 'Comrades Marathon');
    expect(searchEvents('two oc').length, 2);
    expect(searchEvents('soweto').length, greaterThanOrEqualTo(2));
    expect(searchEvents(''), isEmpty);
  });

  test('next date rolls into next year once the month has passed', () {
    const e = RaceEvent('X', null, 10, 'June', month: 6);
    expect(e.nextDate(DateTime(2026, 3, 10)), DateTime(2026, 6, 1));
    expect(e.nextDate(DateTime(2026, 6, 20)), DateTime(2026, 6, 1));
    expect(e.nextDate(DateTime(2026, 7, 1)), DateTime(2027, 6, 1));
    expect(const RaceEvent('Y', null, 5, 'Saturdays').nextDate(), isNull);
  });
}

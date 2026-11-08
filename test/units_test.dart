import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/core/settings.dart';
import 'package:runners_journey/core/units.dart';
import 'package:runners_journey/features/races/race.dart';
import 'package:runners_journey/features/settings/settings_screen.dart';

void main() {
  tearDown(() => settings.unit = DistanceUnit.km);

  test('formats kilometres and miles', () {
    expect(formatDistance(10, miles: false), '10 km');
    expect(formatDistance(10, miles: true), '6.2 mi');
    expect(formatDistance(21.0975, miles: false), '21.1 km');
    expect(formatDistance(42.195, miles: true), '26.2 mi');
    expect(formatDistance(250, miles: false), '250 km');
  });

  test('typed miles snap to standard race distances', () {
    expect(tidyKm(fromUnit(6.2, miles: true)), 10.0);
    expect(tidyKm(fromUnit(13.1, miles: true)), 21.0975);
    expect(tidyKm(fromUnit(26.2, miles: true)), 42.195);
    expect(tidyKm(fromUnit(3, miles: true)), 4.83);
  });

  test('pace follows the unit', () {
    expect(formatPace(10, 3000, miles: false), '5:00 /km');
    expect(formatPace(10, 3000, miles: true), '8:03 /mi');
    expect(paceInUnit(300, miles: true), closeTo(482.8, 0.1));
  });

  test('the global setting drives the helpers', () {
    settings.unit = DistanceUnit.mi;
    expect(unitLabel(), 'mi');
    expect(formatDistance(5), '3.1 mi');
  });

  testWidgets('settings screen switches the unit', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.tap(find.text('Miles'));
    await tester.pump();
    expect(settings.unit, DistanceUnit.mi);
    expect(find.text('Frequently asked questions'), findsOneWidget);
  });
}

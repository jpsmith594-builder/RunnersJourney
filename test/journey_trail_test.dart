import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/core/settings.dart';
import 'package:runners_journey/features/map/journey_trail.dart';
import 'package:runners_journey/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings.showTrail = false;
  });

  test('the trail is off by default and the choice is remembered', () async {
    final s = AppSettings();
    await s.load();
    expect(s.showTrail, isFalse);
    await s.setShowTrail(true);
    final again = AppSettings();
    await again.load();
    expect(again.showTrail, isTrue);
  });

  testWidgets('the Settings switch turns the trail on', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    expect(find.text('Show journey trail'), findsOneWidget);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Show journey trail'));
    await tester.pump();
    expect(settings.showTrail, isTrue);
  });

  testWidgets('the trail paints and animates without errors', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SizedBox(
        width: 300,
        height: 300,
        child: JourneyTrail(legs: [
          TrailLeg(Offset(20, 280), Offset(150, 150)),
          TrailLeg(Offset(150, 150), Offset(260, 30), planned: true),
          TrailLeg(Offset(-5000, -5000), Offset(-4000, -4000)),
        ]),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(JourneyTrail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduce motion keeps the dots still', (tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        home: JourneyTrail(legs: [TrailLeg(Offset(0, 0), Offset(100, 100))]),
      ),
    ));
    // Settles at once: nothing is repeating.
    await tester.pumpAndSettle();
    expect(find.byType(JourneyTrail), findsOneWidget);
  });

  group('buildLegs', () {
    TrailStop stop(String town, double x, {bool planned = false}) =>
        TrailStop(town, Offset(x, 0), planned: planned);

    test('joins consecutive races in different towns', () {
      final legs = buildLegs([stop('a', 0), stop('b', 10), stop('c', 20)]);
      expect(legs, hasLength(2));
      expect(legs.first.from.dx, 0);
      expect(legs.last.to.dx, 20);
    });

    test('same-town races are not joined', () {
      final legs = buildLegs([stop('a', 0), stop('a', 0), stop('b', 10)]);
      expect(legs, hasLength(1));
    });

    test('a repeated route is drawn once, bolder, following the newest trip',
        () {
      final legs = buildLegs([
        stop('a', 0),
        stop('b', 10),
        stop('c', 20),
        stop('b', 10),
        stop('a', 0),
      ]);
      // a-b, b-c, c-b, b-a: three distinct routes (a-b twice, b-c twice).
      expect(legs, hasLength(2));
      final ab = legs.firstWhere((l) => l.repeats == 2 && l.to.dx == 0);
      expect(ab.from.dx, 10); // newest trip went b to a
    });

    test('older legs fade and the newest is strongest', () {
      final legs =
          buildLegs([stop('a', 0), stop('b', 10), stop('c', 20), stop('d', 30)]);
      expect(legs.first.strength, closeTo(0.25, 1e-9));
      expect(legs.last.strength, 1.0);
      expect(legs[1].strength, greaterThan(legs.first.strength));
    });

    test('a planned race makes its leg lighter', () {
      final legs = buildLegs([stop('a', 0), stop('b', 10, planned: true)]);
      expect(legs.single.planned, isTrue);
    });

    test('a single leg is fully strong', () {
      expect(buildLegs([stop('a', 0), stop('b', 10)]).single.strength, 1.0);
    });
  });
}

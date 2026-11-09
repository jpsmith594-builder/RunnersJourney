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
    await tester.tap(find.byType(SwitchListTile));
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
}

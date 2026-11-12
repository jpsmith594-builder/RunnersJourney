import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/core/brand.dart';
import 'package:runners_journey/core/invite.dart';
import 'package:runners_journey/core/season.dart';
import 'package:runners_journey/core/settings.dart';
import 'package:runners_journey/features/map/season_filter.dart';
import 'package:runners_journey/features/profile/share_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('vivid map colours are on by default and remembered', () async {
    final s = AppSettings();
    await s.load();
    expect(s.vividMap, isTrue);
    await s.setVividMap(false);
    final again = AppSettings();
    await again.load();
    expect(again.vividMap, isFalse);
  });

  test('vivid filter differs from the plain one for every season', () {
    for (final season in Season.values) {
      expect(seasonFilter(season, vivid: true),
          isNot(equals(seasonFilter(season))));
    }
  });

  testWidgets('the runner card stage shows the brand message', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CardStage(boundaryKey: GlobalKey(), child: const SizedBox()),
    ));
    expect(find.text(brandMessage), findsOneWidget);
    expect(find.text(inviteLine), findsOneWidget);
    expect(find.text(websiteHost), findsOneWidget);
  });

  test('shared text carries the invitation and the website', () {
    final t = withInvite('My 2026 in running');
    expect(t, startsWith('My 2026 in running'));
    expect(t, contains(websiteUrl));
    expect(t, contains(inviteLine));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/celebrate/celebration_dialog.dart';
import 'package:runners_journey/features/celebrate/celebrations.dart';
import 'package:runners_journey/features/goals/goals.dart';
import 'package:runners_journey/features/races/race.dart';

Race run(int month, double km, int secs, {String name = 'Run'}) => Race(
    name: name,
    date: DateTime(2026, month, 5),
    status: RaceStatus.completed,
    distanceKm: km,
    finishTimeSeconds: secs);

void main() {
  final now = DateTime(2026, 12, 1);

  test('a faster time at a standard distance is a personal best', () {
    final before = [run(1, 10, 3000)];
    final after = [...before, run(3, 10, 2940)];
    final c = detectCelebrations(
        before: before, after: after, goals: const {}, now: now);
    final pb = c.where((e) => e.title == 'New personal best!').toList();
    expect(pb, hasLength(1));
    expect(pb.first.message, contains('10 km'));
    expect(pb.first.message, contains('49:00'));
    expect(pb.first.message, contains('01:00 faster'));
  });

  test('a first time, a slower time or an odd distance is no personal best',
      () {
    bool hasPb(List<Race> b, List<Race> a) => detectCelebrations(
            before: b, after: a, goals: const {}, now: now)
        .any((e) => e.title == 'New personal best!');
    expect(hasPb([], [run(1, 10, 3000)]), isFalse);
    expect(hasPb([run(1, 10, 3000)], [run(1, 10, 3000), run(2, 10, 3100)]),
        isFalse);
    expect(hasPb([run(1, 7, 3000)], [run(1, 7, 3000), run(2, 7, 2000)]),
        isFalse);
  });

  test('earning a badge is celebrated once', () {
    final one = [run(1, 10, 3000)];
    final c = detectCelebrations(
        before: const [], after: one, goals: const {}, now: now);
    expect(c.any((e) => e.title.startsWith('Badge earned')), isTrue);
    final again = detectCelebrations(
        before: one, after: one, goals: const {}, now: now);
    expect(again, isEmpty);
  });

  test('crossing into a new category is celebrated', () {
    // 13 races x 6 = 78 points; one more finished race pushes past 80.
    final before = [for (var i = 0; i < 13; i++) run(1 + i % 12, 3, 1200)];
    final after = [...before, run(12, 3, 1200)];
    final c = detectCelebrations(
        before: before, after: after, goals: const {}, now: now);
    expect(c.any((e) => e.title == 'New category: Rookie'), isTrue);
  });

  test('reaching the yearly goal is celebrated only on the save that does it',
      () {
    final before = [run(1, 5, 1500)];
    final after = [...before, run(2, 5, 1500)];
    final goals = {2026: const YearGoal(2026, races: 2)};
    expect(
        detectCelebrations(
                before: before, after: after, goals: goals, now: now)
            .any((e) => e.title == 'Goal reached!'),
        isTrue);
    expect(
        detectCelebrations(
                before: after, after: [...after, run(3, 5, 1500)],
                goals: goals, now: now)
            .any((e) => e.title == 'Goal reached!'),
        isFalse);
  });

  testWidgets('popup steps through each celebration', (tester) async {
    final items = [
      const Celebration('One', 'first', Icons.star, Colors.red),
      const Celebration('Two', 'second', Icons.flag, Colors.green),
    ];
    await tester.pumpWidget(MaterialApp(home: CelebrationPopup(items: items)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('One'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Nice!'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}

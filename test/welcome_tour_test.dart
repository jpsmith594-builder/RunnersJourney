import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/help/welcome_tour.dart';

void main() {
  testWidgets('swipes through every page and closes on the last', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => TextButton(
            onPressed: () => Navigator.of(c)
                .push(MaterialPageRoute(builder: (_) => const WelcomeTour())),
            child: const Text('open')),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Your life on a map'), findsOneWidget);
    for (var i = 1; i < tourPages.length; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text(tourPages[i].title), findsOneWidget);
    }
    expect(find.text('Skip'), findsNothing);
    await tester.tap(find.text('Start my journey'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}

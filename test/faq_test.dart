import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/help/faq_screen.dart';

void main() {
  test('every question has an answer and the topics are not empty', () {
    for (final s in faqSections) {
      expect(s.items, isNotEmpty, reason: s.title);
      for (final i in s.items) {
        expect(i.question.trim(), isNotEmpty);
        expect(i.answer.trim(), isNotEmpty);
      }
    }
  });

  testWidgets('shows the topics and opens an answer', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FaqScreen()));
    expect(find.text('Your runner card'), findsOneWidget);
    expect(find.text('How does the rating work?'), findsOneWidget);
    await tester.tap(find.text('How does the rating work?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('score from 0 to 1000'), findsOneWidget);
  });
}

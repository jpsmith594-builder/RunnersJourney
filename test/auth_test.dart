import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/auth/set_password_screen.dart';

void main() {
  test('new password rules', () {
    expect(passwordProblem('abc', 'abc'), isNotNull);
    expect(passwordProblem('abcdef', 'abcdeg'), isNotNull);
    expect(passwordProblem('abcdef', 'abcdef'), isNull);
  });
}

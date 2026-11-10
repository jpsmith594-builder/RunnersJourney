import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/auth/set_password_screen.dart';

void main() {
  test('new password rules', () {
    expect(passwordProblem('abc', 'abc'), isNotNull);
    expect(passwordProblem('abcdefg', 'abcdefg'), isNotNull); // 7 characters
    expect(passwordProblem('abcdefgh', 'abcdefgi'), isNotNull);
    expect(passwordProblem('abcdefgh', 'abcdefgh'), isNull);
  });
}

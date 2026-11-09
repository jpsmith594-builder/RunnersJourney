import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/core/errors.dart';
import 'package:runners_journey/core/load_error.dart';

void main() {
  test('network problems are recognised', () {
    expect(isOffline(const SocketException('Failed host lookup')), true);
    expect(isOffline(TimeoutException('slow')), true);
    expect(isOffline(Exception('ClientException: Connection closed')), true);
    expect(isOffline(Exception('duplicate key value')), false);
  });

  test('messages are friendly offline and detailed otherwise', () {
    expect(failMessage('Could not save', const SocketException('x')),
        offlineMessage);
    expect(failMessage('Could not save', Exception('bad')),
        'Could not save: Exception: bad');
    expect(describeError(TimeoutException('t')), offlineMessage);
  });

  testWidgets('load error offers a retry', (tester) async {
    var tries = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: LoadError(
                title: 'Could not load', message: 'm', onRetry: () => tries++))));
    await tester.tap(find.text('Try again'));
    expect(tries, 1);
  });
}

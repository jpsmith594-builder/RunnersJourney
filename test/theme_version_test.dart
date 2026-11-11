import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/core/theme.dart';
import 'package:runners_journey/core/version.dart';

void main() {
  test('Settings version matches pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    expect(line.replaceFirst('version:', '').trim(), startsWith('$appVersion+'));
  });

  Future<Color?> titleColor(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const Scaffold(
        body: Column(children: [
          ListTile(title: Text('Title'), subtitle: Text('Sub')),
          SwitchListTile(value: true, onChanged: null, title: Text('Switch')),
        ]),
      ),
    ));
    return tester.renderObject<RenderParagraph>(find.text('Title')).text.style?.color;
  }

  testWidgets('list text is dark on the light theme', (tester) async {
    final c = await titleColor(tester, AppTheme.light());
    expect(c, isNotNull);
    expect(c!.computeLuminance(), lessThan(0.3));
  });

  testWidgets('list text is light on the dark theme', (tester) async {
    final c = await titleColor(tester, AppTheme.dark());
    expect(c, isNotNull);
    expect(c!.computeLuminance(), greaterThan(0.7));
  });
}

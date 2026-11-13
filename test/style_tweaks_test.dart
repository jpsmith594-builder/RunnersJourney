import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/map/engine/style_tweaks.dart';

void main() {
  Map<String, dynamic> run(Object field) {
    final out = jsonDecode(localiseLabels(jsonEncode({
      'layers': [
        {
          'id': 'x',
          'layout': {'text-field': field},
        },
        {'id': 'no-layout'},
      ],
    }))) as Map<String, dynamic>;
    return (out['layers'] as List).first['layout'] as Map<String, dynamic>;
  }

  test('name tokens become English-first', () {
    for (final f in ['{name}', '{name:latin}', '{name:latin}\n{name:nonlatin}']) {
      final v = run(f)['text-field'] as List;
      expect(v.first, 'coalesce');
      expect(v[1], ['get', 'name:en']);
      expect(v.last, ['get', 'name']);
    }
  });

  test('name expressions inside bigger expressions are localised', () {
    final v = run([
      'concat',
      ['get', 'name'],
      ' ',
      ['get', 'ele'],
    ])['text-field'] as List;
    expect(v.first, 'concat');
    expect((v[1] as List).first, 'coalesce');
    expect(v[3], ['get', 'ele']);
  });

  test('other label fields are left alone', () {
    expect(run('{ref}')['text-field'], '{ref}');
    expect(run(['get', 'housenumber'])['text-field'], ['get', 'housenumber']);
  });
}

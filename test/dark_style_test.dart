import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/map/engine/dark_style.dart';
import 'package:runners_journey/features/map/spike/style_recolour.dart';

double lum(Rgba c) => (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) / 255;

Rgba dark(String css, DarkRole role) =>
    darkenColour(parseCssColour(css)!, role);

void main() {
  test('land, water and park all become dark', () {
    for (final css in ['#f8f4f0', '#aad3df', '#d8e8c8', '#add19e']) {
      expect(lum(dark(css, DarkRole.fill)), lessThan(0.3), reason: css);
    }
  });

  test('roads stay lighter than the land, land lighter than water', () {
    final land = lum(dark('#f8f4f0', DarkRole.fill));
    final road = lum(dark('#ffffff', DarkRole.fill));
    final water = lum(dark('#aad3df', DarkRole.fill));
    expect(road, greaterThan(land));
    expect(land, greaterThan(water));
  });

  test('water stays blue and greys turn slate', () {
    final water = dark('#aad3df', DarkRole.fill);
    expect(water.b, greaterThan(water.r));
    final land = dark('#f8f4f0', DarkRole.fill);
    expect(land.b, greaterThan(land.r));
  });

  test('labels go light and their outlines go dark', () {
    expect(lum(dark('#333333', DarkRole.label)), greaterThan(0.6));
    expect(lum(dark('#ffffff', DarkRole.halo)), lessThan(0.2));
  });

  test('transparency is kept', () {
    expect(dark('rgba(255,255,255,0.4)', DarkRole.fill).a, 0.4);
  });

  test('darkenStyle only changes colours and picks the role by property', () {
    final styled = darkenStyle(jsonEncode({
      'layers': [
        {
          'id': 'label',
          'paint': {
            'text-color': '#333333',
            'text-halo-color': '#ffffff',
            'text-opacity': 0.5,
          },
        },
        {
          'id': 'bg',
          'paint': {'background-color': '#f8f4f0'},
        },
      ],
    }));
    final layers = (jsonDecode(styled) as Map)['layers'] as List;
    final label = layers[0]['paint'] as Map;
    expect(label['text-opacity'], 0.5);
    expect(lum(parseCssColour(label['text-color'] as String)!),
        greaterThan(0.6));
    expect(lum(parseCssColour(label['text-halo-color'] as String)!),
        lessThan(0.2));
    final bg = parseCssColour(
        (layers[1]['paint'] as Map)['background-color'] as String)!;
    expect(lum(bg), lessThan(0.3));
  });

  test('road badge layers are removed', () {
    final out = jsonDecode(darkenStyle(jsonEncode({
      'layers': [
        {'id': 'road_shield', 'paint': {}},
        {'id': 'water', 'paint': {'fill-color': '#aad3df'}},
      ],
    }))) as Map;
    expect((out['layers'] as List).length, 1);
  });
}

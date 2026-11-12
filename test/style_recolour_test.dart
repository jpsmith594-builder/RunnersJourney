import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/core/season.dart';
import 'package:runners_journey/features/map/season_filter.dart';
import 'package:runners_journey/features/map/spike/style_recolour.dart';

void main() {
  test('parses hex, rgb and hsl colours and ignores words', () {
    final a = parseCssColour('#ff8000')!;
    expect([a.r, a.g, a.b, a.a], [255, 128, 0, 1]);
    final b = parseCssColour('rgba(10, 20, 30, 0.5)')!;
    expect([b.r, b.g, b.b, b.a], [10, 20, 30, 0.5]);
    final c = parseCssColour('hsl(0, 100%, 50%)')!;
    expect([c.r.round(), c.g.round(), c.b.round()], [255, 0, 0]);
    expect(parseCssColour('interpolate'), isNull);
    expect(parseCssColour('get'), isNull);
  });

  test('recolours paint colours, including inside expressions', () {
    final style = jsonEncode({
      'layers': [
        {
          'id': 'bg',
          'paint': {
            'background-color': '#808080',
            'background-opacity': 1,
          },
        },
        {
          'id': 'water',
          'paint': {
            'fill-color': [
              'interpolate',
              ['linear'],
              ['zoom'],
              4,
              '#336699',
              10,
              'rgba(0,0,0,0.5)',
            ],
          },
        },
        {'id': 'no-paint'},
      ],
    });
    // Winter drains saturation; the grey stays grey, the blue gets greyer.
    final out = jsonDecode(recolourStyle(
            style, seasonMatrix(Season.winter))) as Map<String, dynamic>;
    final layers = out['layers'] as List;
    final bg = (layers[0]['paint'] as Map)['background-color'] as String;
    expect(bg.startsWith('rgba('), isTrue);
    expect((layers[0]['paint'] as Map)['background-opacity'], 1);
    final water = (layers[1]['paint'] as Map)['fill-color'] as List;
    expect(water[0], 'interpolate');
    expect(water[3], 4);
    expect((water[4] as String).startsWith('rgba('), isTrue);
    expect(water[5], 10);
    expect((water[6] as String).endsWith(',0.5)'), isTrue);
  });
}

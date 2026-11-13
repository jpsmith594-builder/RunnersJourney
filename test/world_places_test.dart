import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/map/world_places.dart';

const _csv = '''
Shanghai|CN|23|31.2222|121.4581|22315474
Zürich|CH|ZH|47.3667|8.5500|341730
Berlin|DE|16|52.5244|13.4105|3426354
Bela-Bela|ZA|09|-24.8833|28.2833|0
Springfield|US|IL|39.8017|-89.6437|114230
Springfield|US|MA|42.1015|-72.5898|153060
Knysna|ZA|11|-34.0363|23.0471|68659
New Berlin|US|WI|42.9764|-88.1084|39584
''';

void main() {
  final index = WorldIndex.fromCsv(_csv);

  test('loads every line', () => expect(index.length, 8));

  test('ignores accents and hyphens', () {
    expect(index.search('zurich').single.name, 'Zürich');
    expect(index.search('bela bela').single.name, 'Bela-Bela');
    expect(index.search('Bela-Bela').single.name, 'Bela-Bela');
  });

  test('start of the name beats a later word, and bigger towns come first', () {
    final r = index.search('berlin');
    expect(r.first.name, 'Berlin');
    expect(r.last.name, 'New Berlin');
    final s = index.search('springf');
    expect(s.first.province, 'MA');
    expect(s.length, 2);
  });

  test('gives country names and South African provinces', () {
    final k = index.search('knysna').single;
    expect(k.country, 'South Africa');
    expect(k.province, 'Western Cape');
    expect(k.lat, closeTo(-34.0363, 1e-6));
    expect(index.search('berlin').first.country, 'Germany');
  });

  test('needs at least two letters', () {
    expect(index.search('b'), isEmpty);
    expect(index.search(''), isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/medals/medal.dart';

void main() {
  test('unknown metal and ribbon names fall back to gold and blue', () {
    expect(metalFrom(null), MedalMetal.gold);
    expect(metalFrom('platinum'), MedalMetal.gold);
    expect(ribbonFrom('teal'), MedalRibbon.blue);
  });

  test('every metal and ribbon name round-trips', () {
    for (final m in MedalMetal.values) {
      expect(metalFrom(m.name), m);
    }
    for (final r in MedalRibbon.values) {
      expect(ribbonFrom(r.name), r);
    }
  });

  test('a race medal picks the matching metal', () {
    expect(metalForRaceMedal('silver'), MedalMetal.silver);
    expect(metalForRaceMedal(null), isNull);
    expect(metalForRaceMedal('platinum'), isNull);
  });

  test('metal and ribbon names match the database check constraints', () {
    expect(MedalMetal.values.map((m) => m.name),
        ['gold', 'silver', 'bronze', 'titanium']);
    expect(MedalRibbon.values.map((r) => r.name),
        ['blue', 'green', 'red', 'purple', 'orange', 'yellow', 'pink', 'black']);
  });
}

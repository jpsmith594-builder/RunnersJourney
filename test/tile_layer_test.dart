import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/map/map_tiles.dart';
import 'package:runners_journey/features/map/places.dart';
import 'package:runners_journey/features/map/tile_layer.dart';

void main() {
  group('tile levels', () {
    test('picks the smallest level that is sharp enough', () {
      expect(pickLevel(kGlobalLevels, 1000).wFull, 1800);
      expect(pickLevel(kGlobalLevels, 2500).wFull, 3600);
      expect(pickLevel(kGlobalLevels, 99999).wFull, 3600);
      expect(pickLevel(kRegionLevels, 7000).wFull, 7200);
      expect(pickLevel(kRegionLevels, 20000).wFull, 28800);
    });

    test('whole map needs every tile of a global level', () {
      final l = kGlobalLevels.first;
      expect(visibleTiles(l, 0, 0, 1, 1).length, l.cols * l.rows);
    });

    test('a small window needs one tile and sits inside its rect', () {
      final l = kGlobalLevels.last;
      final t = visibleTiles(l, 0.01, 0.01, 0.02, 0.02);
      expect(t.length, 1);
      final r = tileRect(l, t.first, 900);
      expect(r.left, lessThanOrEqualTo(0.01 * 900));
      expect(r.right, greaterThanOrEqualTo(0.02 * 900));
    });

    test('region levels cover Cape Town only', () {
      final l = kRegionLevels.last;
      expect(visibleTiles(l, 0.5, 0.2, 0.6, 0.3), isEmpty);
      final cape = placeByName('Cape Town')!;
      expect(
          visibleTiles(l, cape.fx - .001, cape.fy - .001, cape.fx + .001,
              cape.fy + .001),
          isNotEmpty);
    });
  });

  group('places', () {
    test('Cape Town suburbs appear only at deep tiers and sit near the city', () {
      final ct = placeByName('Cape Town')!;
      final sub = kPlaces.where((p) => p.tier >= 4).toList();
      expect(sub.length, greaterThan(20));
      for (final p in sub) {
        expect((p.fx - ct.fx).abs(), lessThan(0.03), reason: p.name);
        expect((p.fy - ct.fy).abs(), lessThan(0.04), reason: p.name);
      }
    });
  });
}

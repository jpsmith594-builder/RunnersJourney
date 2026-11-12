import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/map/engine/tile_failures.dart';

void main() {
  test('reports once after enough failures, then waits for the cooldown', () {
    var now = DateTime(2026, 11, 12, 20);
    final sent = <List<Object>>[];
    final r = TileFailureReporter(
      send: (t, p) => sent.add(p),
      now: () => now,
    );
    for (var i = 0; i < 4; i++) {
      r.record(9, Exception('403'));
    }
    expect(sent, isEmpty);
    r.record(9, Exception('403'));
    expect(sent.length, 1);
    expect(sent.first[0], 5);
    expect(sent.first[2], 9);

    // More failures inside the cooldown are not reported again.
    for (var i = 0; i < 10; i++) {
      r.record(9, Exception('403'));
    }
    expect(sent.length, 1);

    // After the cooldown it can report again.
    now = now.add(const Duration(minutes: 11));
    for (var i = 0; i < 5; i++) {
      r.record(10, Exception('403'));
    }
    expect(sent.length, 2);
  });

  test('failures spread over more than a minute are ignored', () {
    var now = DateTime(2026, 11, 12, 20);
    var sent = 0;
    final r = TileFailureReporter(send: (t, p) => sent++, now: () => now);
    for (var i = 0; i < 20; i++) {
      r.record(9, Exception('x'));
      now = now.add(const Duration(seconds: 30));
    }
    expect(sent, 0);
  });

  test('scrub removes the key and tile addresses', () {
    final t = TileFailureReporter.scrub(
        'HttpException: bad status 403, uri = https://api.maptiler.com/maps/x/256/9/280/290.png?key=SECRET123');
    expect(t.contains('SECRET123'), isFalse);
    expect(t.contains('maptiler.com'), isFalse);
    expect(TileFailureReporter.scrub('key=abc&x=1'), 'key=***&x=1');
  });
}

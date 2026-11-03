import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/core/season.dart';
import 'package:runners_journey/features/races/race.dart';

void main() {
  test('pace from distance and time', () {
    expect(formatPace(10, 3000), '5:00 /km');
    expect(formatPace(21.1, 6300), '4:59 /km');
    expect(formatPace(null, 3000), isNull);
    expect(formatPace(5, null), isNull);
    expect(formatPace(0, 100), isNull);
  });

  test('parseDuration handles h:mm:ss, mm:ss, minutes and bad input', () {
    expect(parseDuration('1:02:03'), 3723);
    expect(parseDuration('45:30'), 2730);
    expect(parseDuration('45'), 2700);
    expect(parseDuration(''), isNull);
    expect(parseDuration('abc'), isNull);
  });

  test('formatDuration round-trips', () {
    expect(formatDuration(3723), '1:02:03');
    expect(formatDuration(2730), '45:30');
    expect(formatDuration(null), '-');
  });

  test('seasonFor flips by hemisphere', () {
    final oct = DateTime(2026, 10, 12);
    expect(seasonFor(oct, southern: true), Season.spring);
    expect(seasonFor(oct, southern: false), Season.autumn);
    final jan = DateTime(2026, 1, 5);
    expect(seasonFor(jan, southern: true), Season.summer);
    expect(seasonFor(jan, southern: false), Season.winter);
  });
}

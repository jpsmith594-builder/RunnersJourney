import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/races/race.dart';
import 'package:runners_journey/features/subscription/limits.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Race _r(RaceStatus s) =>
    Race(name: 'r', date: DateTime(2026, 1, 1), status: s);

void main() {
  test('planned races do not count towards the free limit', () {
    final races = [
      _r(RaceStatus.planned),
      _r(RaceStatus.planned),
      _r(RaceStatus.completed),
      _r(RaceStatus.dnf),
    ];
    expect(countedRaces(races), 2);
  });

  test('free plan notices', () {
    expect(freePlanNotice(0, subscribed: false), isNull);
    expect(freePlanNotice(2, subscribed: false), isNull);
    expect(freePlanNotice(3, subscribed: false), '3 of 5 free races used.');
    expect(freePlanNotice(5, subscribed: false), contains('all 5'));
    expect(freePlanNotice(7, subscribed: false), contains('read-only'));
    expect(freePlanNotice(7, subscribed: true), isNull);
  });

  test('database limit errors are recognised', () {
    expect(limitKind(const PostgrestException(message: 'free_limit')),
        'free_limit');
    expect(limitKind(const PostgrestException(message: 'read_only')),
        'read_only');
    expect(limitKind(const PostgrestException(message: 'photo_limit')),
        'photo_limit');
    expect(limitKind(const PostgrestException(message: 'something else')),
        isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/profile/profile.dart';

void main() {
  test('gender codes round-trip and unknown values are ignored', () {
    for (final g in Gender.values) {
      expect(GenderInfo.fromDb(g.db), g);
    }
    expect(GenderInfo.fromDb(null), isNull);
    expect(GenderInfo.fromDb('something else'), isNull);
    expect(Gender.male.short, 'M');
    expect(Gender.nonBinary.short, 'NB');
    expect(Gender.undisclosed.short, isNull);
  });

  test('age is derived from the birth year', () {
    const p = RunnerProfile(birthYear: 1990);
    expect(p.ageAt(DateTime(2026, 11, 2)), 36);
    expect(const RunnerProfile().ageAt(DateTime(2026, 11, 2)), isNull);
  });

  test('profile survives a map round trip', () {
    const p = RunnerProfile(
      displayName: 'Thandi',
      club: 'Harbour Harriers',
      homeTown: 'Durban',
      favouriteDistance: '21K',
      gender: Gender.female,
      birthYear: 1994,
    );
    final back = RunnerProfile.fromMap(p.toMap());
    expect(back.displayName, 'Thandi');
    expect(back.gender, Gender.female);
    expect(back.birthYear, 1994);
    expect(back.favouriteDistance, '21K');
  });
}

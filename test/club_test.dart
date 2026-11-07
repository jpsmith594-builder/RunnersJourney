import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/clubs/club.dart';
import 'package:runners_journey/features/profile/profile.dart';

void main() {
  const sea = Club(id: '1', name: 'Sea Point Striders', score: 0.9, exact: false);
  const same = Club(id: '2', name: 'Fish Hoek A.C', score: 1, exact: true);
  const far = Club(id: '3', name: 'Zandvlei Athletic Club', score: 0.2);

  group('decideClub', () {
    test('empty text means no club', () {
      expect(decideClub('  ', const [sea]).decision, ClubDecision.none);
    });

    test('the same club after cleaning up is used without asking', () {
      final d = decideClub('fish hoek athletic club', const [same, far]);
      expect(d.decision, ClubDecision.useExisting);
      expect(d.club?.id, '2');
    });

    test('exact name match ignores capitals', () {
      final d = decideClub('sea point striders', const [sea]);
      expect(d.decision, ClubDecision.useExisting);
    });

    test('a close spelling asks "did you mean"', () {
      final d = decideClub('Seapoint Stridrs', const [sea, far]);
      expect(d.decision, ClubDecision.askDidYouMean);
      expect(d.club?.name, 'Sea Point Striders');
    });

    test('nothing alike creates a new club', () {
      expect(decideClub('Brand New Harriers', const [far]).decision,
          ClubDecision.createNew);
      expect(decideClub('Brand New Harriers', const []).decision,
          ClubDecision.createNew);
    });
  });

  test('club subtitle shows area and members', () {
    expect(const Club(name: 'X', area: 'Hout Bay', members: 14).subtitle,
        'Hout Bay, 14 members');
    expect(const Club(name: 'X', members: 1).subtitle, '1 member');
    expect(const Club(name: 'X').subtitle, '');
  });

  test('club link is only saved when set, or when clearing', () {
    expect(const RunnerProfile(club: 'A').toMap().containsKey('club_id'),
        isFalse);
    expect(const RunnerProfile(club: 'A', clubId: 'x').toMap()['club_id'], 'x');
    final cleared = const RunnerProfile().toMap(includeClubId: true);
    expect(cleared.containsKey('club_id'), isTrue);
    expect(cleared['club_id'], isNull);
    expect(RunnerProfile.fromMap({'club': 'A', 'club_id': 'x'}).clubId, 'x');
  });
}

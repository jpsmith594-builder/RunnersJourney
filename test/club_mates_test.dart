import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/clubs/club_mates.dart';

void main() {
  test('button label and state for each friendship status', () {
    expect(clubMateAction('none'), (label: 'Add friend', enabled: true));
    expect(clubMateAction('pending_out'), (label: 'Request sent', enabled: false));
    expect(clubMateAction('pending_in'), (label: 'Accept', enabled: true));
    expect(clubMateAction('friends'), (label: 'Friends', enabled: false));
    expect(clubMateAction('something else').enabled, isTrue);
  });

  test('a club-mate is read from the database row', () {
    final m = ClubMate.fromMap({
      'user_id': 'u1',
      'display_name': 'Thandi',
      'friend_status': 'pending_in',
    });
    expect(m.userId, 'u1');
    expect(m.name, 'Thandi');
    expect(m.status, 'pending_in');
    expect(
        ClubMate.fromMap({'user_id': 'u2', 'display_name': null}).name, 'Runner');
    expect(ClubMate.fromMap({'user_id': 'u2'}).status, 'none');
  });
}

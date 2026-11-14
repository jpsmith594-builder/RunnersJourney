import 'package:flutter_test/flutter_test.dart';
import 'package:runners_journey/features/growth/growth_repository.dart';
import 'package:runners_journey/features/subscription/limits.dart';

void main() {
  test('free months follow the referral ladder', () {
    expect(referralMonthsFor(0), 0);
    expect(referralMonthsFor(2), 0);
    expect(referralMonthsFor(3), 1);
    expect(referralMonthsFor(5), 2);
    expect(referralMonthsFor(10), 3);
    expect(referralMonthsFor(20), 4);
    expect(referralMonthsFor(30), 6);
    expect(referralMonthsFor(99), 6);
  });

  test('summary reads the server answer and words the next step', () {
    final s = ReferralSummary.fromJson({
      'code': 'REF-ABC234',
      'joined': 5,
      'subscribed_pending': 1,
      'qualified': 4,
      'months_earned': 1,
      'next_tier_at': 5,
      'months_banked': 1,
      'bonus_slots': 2,
    });
    expect(s.code, 'REF-ABC234');
    expect(s.bonusSlots, 2);
    expect(s.nextTierText, '1 more subscriber for 2 free months');
    final top = ReferralSummary.fromJson(
        {'code': 'REF-X', 'qualified': 30, 'next_tier_at': null});
    expect(top.nextTierText, isNull);
  });

  test('club and friend codes carry different offers', () {
    final club = CodeResult.fromJson(
        {'kind': 'club', 'club': 'Bellville Runners', 'discount_pct': 15});
    final friend =
        CodeResult.fromJson({'kind': 'referral', 'discount_pct': 10});
    expect(club.offerTag, 'club15');
    expect(club.headline, contains('Bellville'));
    expect(friend.offerTag, 'ref10');
    expect(friend.isClub, isFalse);
  });

  test('database code errors become friendly messages', () {
    expect(codeErrorMessage('code_invalid'), contains('not found'));
    expect(codeErrorMessage('code_already_used'), contains('one code'));
    expect(codeErrorMessage('code_not_new'), contains('new subscribers'));
    expect(codeErrorMessage('code_own'), contains('own code'));
    expect(codeErrorMessage('something else'), isNull);
  });

  test('earned slots raise the free limit in the home notice', () {
    expect(freePlanNotice(4, subscribed: false, limit: 7), isNull);
    expect(freePlanNotice(5, subscribed: false, limit: 7), '5 of 7 free races used.');
    expect(freePlanNotice(7, subscribed: false, limit: 7), contains('all 7'));
    expect(freePlanNotice(8, subscribed: false, limit: 7), contains('read-only'));
  });
}

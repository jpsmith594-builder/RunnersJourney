import 'package:supabase_flutter/supabase_flutter.dart';

/// What a code unlocks.
class CodeResult {
  /// 'club' or 'referral'.
  final String kind;
  final String? club;
  final int discountPct;
  const CodeResult(
      {required this.kind, this.club, required this.discountPct});

  bool get isClub => kind == 'club';

  /// The Play offer tag the matching discount carries (set in Play Console).
  String get offerTag => isClub ? 'club15' : 'ref10';

  factory CodeResult.fromJson(Map<String, dynamic> j) => CodeResult(
        kind: j['kind'] as String,
        club: j['club'] as String?,
        discountPct: (j['discount_pct'] as num?)?.toInt() ?? 0,
      );

  String get headline => isClub
      ? '${club ?? 'Club'} code accepted'
      : 'Friend code accepted';

  String get detail =>
      '$discountPct% off your first year of the yearly plan. After that it '
      'goes back to the normal price.';
}

/// The numbers on the "Invite and earn" screen.
class ReferralSummary {
  final String code;
  final int joined;
  final int pending;
  final int qualified;
  final int monthsEarned;
  final int? nextTierAt;
  final int monthsBanked;
  final int bonusSlots;

  const ReferralSummary({
    required this.code,
    this.joined = 0,
    this.pending = 0,
    this.qualified = 0,
    this.monthsEarned = 0,
    this.nextTierAt,
    this.monthsBanked = 0,
    this.bonusSlots = 0,
  });

  factory ReferralSummary.fromJson(Map<String, dynamic> j) => ReferralSummary(
        code: j['code'] as String,
        joined: (j['joined'] as num?)?.toInt() ?? 0,
        pending: (j['subscribed_pending'] as num?)?.toInt() ?? 0,
        qualified: (j['qualified'] as num?)?.toInt() ?? 0,
        monthsEarned: (j['months_earned'] as num?)?.toInt() ?? 0,
        nextTierAt: (j['next_tier_at'] as num?)?.toInt(),
        monthsBanked: (j['months_banked'] as num?)?.toInt() ?? 0,
        bonusSlots: (j['bonus_slots'] as num?)?.toInt() ?? 0,
      );

  /// e.g. "2 more subscribers for 1 free month", or null at the top tier.
  String? get nextTierText {
    final at = nextTierAt;
    if (at == null) return null;
    final months = referralMonthsFor(at);
    final more = at - qualified;
    return '$more more ${more == 1 ? 'subscriber' : 'subscribers'} for '
        '$months free ${months == 1 ? 'month' : 'months'}';
  }
}

/// Free months at a number of paid referrals (matches the database).
int referralMonthsFor(int n) {
  if (n >= 30) return 6;
  if (n >= 20) return 4;
  if (n >= 10) return 3;
  if (n >= 5) return 2;
  if (n >= 3) return 1;
  return 0;
}

/// A friendly message for a failed code, or null if it was something else.
String? codeErrorMessage(Object e) {
  final text = e is PostgrestException ? '${e.message} ${e.details}' : '$e';
  if (text.contains('code_invalid')) {
    return 'That code was not found. Check it and try again.';
  }
  if (text.contains('code_already_used')) {
    return 'You have already used a different code. Only one code can be used.';
  }
  if (text.contains('code_not_new')) {
    return 'Codes are for new subscribers only.';
  }
  if (text.contains('code_own')) {
    return 'You cannot use your own code. Share it with a friend instead.';
  }
  return null;
}

class GrowthRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<CodeResult> redeem(String code) async {
    final res = await _db.rpc('redeem_code', params: {'p_code': code});
    return CodeResult.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<ReferralSummary> summary() async {
    final res = await _db.rpc('referral_summary');
    return ReferralSummary.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// The code this runner has already used, if any.
  Future<CodeResult?> myRedemption() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _db
        .from('code_redemptions')
        .select('kind, code')
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return null;
    final kind = row['kind'] as String;
    return CodeResult(kind: kind, discountPct: kind == 'club' ? 15 : 10);
  }
}

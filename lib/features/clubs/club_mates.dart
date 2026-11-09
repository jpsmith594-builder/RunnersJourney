import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors.dart';

/// A runner in the same club who has chosen to be found.
class ClubMate {
  final String userId;
  final String name;

  /// none, pending_out (you asked), pending_in (they asked) or friends.
  final String status;

  const ClubMate(
      {required this.userId, required this.name, required this.status});

  factory ClubMate.fromMap(Map<String, dynamic> m) => ClubMate(
        userId: m['user_id'] as String,
        name: (m['display_name'] as String?) ?? 'Runner',
        status: (m['friend_status'] as String?) ?? 'none',
      );
}

/// What the button next to a club-mate says and whether it can be pressed.
({String label, bool enabled}) clubMateAction(String status) {
  switch (status) {
    case 'friends':
      return (label: 'Friends', enabled: false);
    case 'pending_out':
      return (label: 'Request sent', enabled: false);
    case 'pending_in':
      return (label: 'Accept', enabled: true);
    default:
      return (label: 'Add friend', enabled: true);
  }
}

/// The opt-in switch and the list of club-mates who also opted in.
class ClubMatesStore extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  bool visible = false;
  bool hasClub = false;
  List<ClubMate> mates = [];
  bool loading = true;
  String? error;

  Future<void> load() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return;
      final row = await _db
          .from('profiles')
          .select('club_id, club_visible')
          .eq('id', uid)
          .maybeSingle();
      hasClub = row?['club_id'] != null;
      visible = hasClub && (row?['club_visible'] as bool? ?? false);
      if (visible) {
        final rows = await _db.rpc('my_club_mates');
        mates = [
          for (final r in rows as List)
            ClubMate.fromMap(Map<String, dynamic>.from(r as Map))
        ];
      } else {
        mates = [];
      }
      error = null;
    } catch (e) {
      error = describeError(e);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> setVisible(bool on) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from('profiles').update({'club_visible': on}).eq('id', uid);
    await load();
  }

  /// Sends (or accepts) a friend request. Returns the club-mate's name.
  Future<String> add(ClubMate m) async {
    final name = await _db.rpc('add_club_mate', params: {'p_user': m.userId});
    await load();
    return name as String;
  }
}

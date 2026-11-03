import 'package:supabase_flutter/supabase_flutter.dart';

import '../profile/profile.dart';
import '../races/race.dart';
import 'friend_entry.dart';

class FriendsRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// The signed-in runner's own friend code.
  Future<String> myCode() async {
    final row = await _db
        .from('profiles')
        .select('friend_code')
        .eq('id', _db.auth.currentUser!.id)
        .maybeSingle();
    return (row?['friend_code'] as String?) ?? '';
  }

  Future<List<FriendEntry>> list() async {
    final rows = await _db.rpc('my_friendships');
    return (rows as List)
        .map((r) => FriendEntry.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Sends a request (or accepts a waiting one). Returns the runner's name.
  Future<String> addByCode(String code) async {
    final name = await _db.rpc('add_friend_by_code', params: {'p_code': code});
    return name as String;
  }

  Future<void> accept(String friendshipId) async {
    await _db
        .from('friendships')
        .update({'status': 'accepted'}).eq('id', friendshipId);
  }

  Future<void> remove(String friendshipId) async {
    await _db.from('friendships').delete().eq('id', friendshipId);
  }

  Future<RunnerProfile> profileOf(String id) async {
    final row = await _db.from('profiles').select().eq('id', id).single();
    return RunnerProfile.fromMap(row);
  }

  Future<List<Race>> racesOf(String id) async {
    final rows =
        await _db.from('races').select().eq('user_id', id).order('race_date');
    return (rows as List)
        .map((r) => Race.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import 'race.dart';

class RaceRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Race>> list() async {
    // Friends are allowed to read each other's races, so always ask for the
    // signed-in runner's own rows only.
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _db
        .from('races')
        .select()
        .eq('user_id', uid)
        .order('race_date');
    return (rows as List)
        .map((r) => Race.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Adds a race and returns its new id.
  Future<String> add(Race race) async {
    final uid = _db.auth.currentUser!.id;
    final row = await _db
        .from('races')
        .insert({...race.toMap(), 'user_id': uid})
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> update(Race race) async {
    await _db.from('races').update(race.toMap()).eq('id', race.id!);
  }

  Future<void> delete(String id) async {
    await _db.from('races').delete().eq('id', id);
  }

  /// True when the runner is in the southern hemisphere (default).
  Future<bool> isSouthern() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return true;
    final row = await _db
        .from('profiles')
        .select('hemisphere')
        .eq('id', uid)
        .maybeSingle();
    return (row?['hemisphere'] as String? ?? 'south') == 'south';
  }
}

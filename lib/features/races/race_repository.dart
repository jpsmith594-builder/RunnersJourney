import 'package:supabase_flutter/supabase_flutter.dart';

import 'race.dart';

class RaceRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Race>> list() async {
    final rows = await _db.from('races').select().order('race_date');
    return (rows as List)
        .map((r) => Race.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(Race race) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from('races').insert({...race.toMap(), 'user_id': uid});
  }

  Future<void> update(Race race) async {
    await _db.from('races').update(race.toMap()).eq('id', race.id!);
  }

  Future<void> delete(String id) async {
    await _db.from('races').delete().eq('id', id);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import 'club.dart';

class ClubRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// Clubs that match what was typed (up to 8), best first.
  Future<List<Club>> search(String q) async {
    final t = q.trim();
    if (t.length < 2) return [];
    final rows = await _db.rpc('search_clubs', params: {'q': t});
    return [
      for (final r in rows as List) Club.fromMap(Map<String, dynamic>.from(r as Map))
    ];
  }

  /// The club with this name, created when it is not in the list yet. Names
  /// that are the same after cleaning up (capitals, dots, "athletic club")
  /// give back the existing club.
  Future<Club> findOrCreate(String name) async {
    final rows =
        await _db.rpc('find_or_create_club', params: {'p_name': name.trim()});
    final r = Map<String, dynamic>.from((rows as List).first as Map);
    return Club(id: r['id'] as String, name: r['name'] as String);
  }
}

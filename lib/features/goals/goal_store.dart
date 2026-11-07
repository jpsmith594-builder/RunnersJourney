import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The runner's yearly goals, kept on their profile row.
class GoalStore extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  int? goalKm;
  int? goalRaces;
  bool loaded = false;

  Future<void> load() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return;
      final row = await _db
          .from('profiles')
          .select('goal_km, goal_races')
          .eq('id', uid)
          .maybeSingle();
      goalKm = row?['goal_km'] as int?;
      goalRaces = row?['goal_races'] as int?;
    } catch (_) {
      // Goals are optional; carry on without them (for example before the
      // database update has been run).
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> save({int? km, int? races}) async {
    final uid = _db.auth.currentUser!.id;
    await _db
        .from('profiles')
        .update({'goal_km': km, 'goal_races': races}).eq('id', uid);
    goalKm = km;
    goalRaces = races;
    notifyListeners();
  }
}

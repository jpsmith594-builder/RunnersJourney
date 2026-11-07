import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'goals.dart';

/// The runner's goals, one set per year, in the `yearly_goals` table.
class GoalStore extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  /// Goals by year.
  Map<int, YearGoal> byYear = {};
  bool loaded = false;

  /// This year's goals.
  int? get goalKm => byYear[DateTime.now().year]?.km;
  int? get goalRaces => byYear[DateTime.now().year]?.races;

  Future<void> load() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return;
      final rows = await _db
          .from('yearly_goals')
          .select('year, goal_km, goal_races')
          .eq('user_id', uid);
      byYear = {
        for (final r in rows as List)
          (r as Map)['year'] as int: YearGoal(
            r['year'] as int,
            km: r['goal_km'] as int?,
            races: r['goal_races'] as int?,
          ),
      };
    } catch (_) {
      // Goals are optional; carry on without them (for example before the
      // database update has been run).
    }
    loaded = true;
    notifyListeners();
  }

  /// Saves the goals for [year]; leaving both empty removes them.
  Future<void> saveFor(int year, {int? km, int? races}) async {
    final uid = _db.auth.currentUser!.id;
    if (km == null && races == null) {
      await _db
          .from('yearly_goals')
          .delete()
          .eq('user_id', uid)
          .eq('year', year);
      byYear = {...byYear}..remove(year);
    } else {
      await _db.from('yearly_goals').upsert({
        'user_id': uid,
        'year': year,
        'goal_km': km,
        'goal_races': races,
      });
      byYear = {...byYear, year: YearGoal(year, km: km, races: races)};
    }
    notifyListeners();
  }

  /// Saves this year's goals.
  Future<void> save({int? km, int? races}) =>
      saveFor(DateTime.now().year, km: km, races: races);
}

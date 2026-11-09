import 'package:flutter/material.dart';

import '../goals/goals.dart';
import '../profile/runner_stats.dart';
import '../races/race.dart';
import '../stats/badges.dart';

/// Something worth a little party after a race is saved.
class Celebration {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  const Celebration(this.title, this.message, this.icon, this.color);
}

const _classNames = {
  5: '5 km',
  10: '10 km',
  21: 'half marathon',
  42: 'marathon',
};

/// Best finish time per standard distance (5, 10, 21, 42), completed races
/// only.
Map<int, int> bestTimes(List<Race> races) {
  final best = <int, int>{};
  for (final r in races) {
    if (r.status != RaceStatus.completed) continue;
    final t = r.finishTimeSeconds;
    final c = distanceClass(r.distanceKm);
    if (t == null || t <= 0 || c == null) continue;
    if (!best.containsKey(c) || t < best[c]!) best[c] = t;
  }
  return best;
}

String _clock(int s) => formatDuration(s);

/// Compares the races before and after a save and lists what to celebrate:
/// new personal bests, newly earned badges, a higher runner-card category and
/// a reached yearly goal. Goals reached earlier are not repeated.
List<Celebration> detectCelebrations({
  required List<Race> before,
  required List<Race> after,
  required Map<int, YearGoal> goals,
  DateTime? now,
}) {
  final out = <Celebration>[];
  final n = now ?? DateTime.now();

  // Personal bests: only when there was an earlier time to beat.
  final b = bestTimes(before), a = bestTimes(after);
  for (final c in [5, 10, 21, 42]) {
    if (b.containsKey(c) && a.containsKey(c) && a[c]! < b[c]!) {
      final gain = b[c]! - a[c]!;
      out.add(Celebration(
          'New personal best!',
          'Your ${_classNames[c]} best is now ${_clock(a[c]!)}, '
              '${_clock(gain)} faster than before.',
          Icons.emoji_events,
          const Color(0xFFF2A900)));
    }
  }

  // Category up.
  final tb = computeStats(before).tier, ta = computeStats(after).tier;
  if (ta.index > tb.index) {
    out.add(Celebration(
        'New category: ${tierName(ta)}',
        'Your runner card moved up from ${tierName(tb)} to ${tierName(ta)}. '
            'That took real racing.',
        Icons.military_tech,
        const Color(0xFF7B3FE4)));
  }

  // Badges.
  final had = {
    for (final r in computeBadges(before))
      if (r.earned) r.badge.id
  };
  for (final r in computeBadges(after)) {
    if (r.earned && !had.contains(r.badge.id)) {
      out.add(Celebration('Badge earned: ${r.badge.title}',
          r.badge.description, r.badge.icon, r.badge.color));
    }
  }

  // Yearly goal.
  final g = goals[n.year];
  if (g != null && !g.isEmpty) {
    GoalProgress p(List<Race> rs) =>
        goalProgress(rs, n.year, goalKm: g.km, goalRaces: g.races, now: n);
    if (yearAchieved(p(after)) && !yearAchieved(p(before))) {
      out.add(const Celebration(
          'Goal reached!',
          'You hit your goal for the year. Time to dream up the next one.',
          Icons.flag,
          Color(0xFF1FA85A)));
    }
  }
  return out;
}

/// "Club runner" style name for a category.
String tierName(CardTier t) => switch (t) {
      CardTier.novice => 'Novice',
      CardTier.rookie => 'Rookie',
      CardTier.club => 'Club runner',
      CardTier.competitor => 'Competitor',
      CardTier.veteran => 'Veteran',
      CardTier.master => 'Master',
      CardTier.elite => 'Elite',
    };

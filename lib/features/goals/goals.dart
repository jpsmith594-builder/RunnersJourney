import '../races/race.dart';
import '../stats/badges.dart';
import '../../core/units.dart';

/// Where a runner stands against their goals for one year. Only finished
/// races count towards the goals.
class GoalProgress {
  final int year;
  final double km;
  final int races;
  final int plannedLeft;
  final int? goalKm;
  final int? goalRaces;

  const GoalProgress({
    required this.year,
    required this.km,
    required this.races,
    required this.plannedLeft,
    this.goalKm,
    this.goalRaces,
  });

  double? get kmFraction =>
      goalKm == null ? null : (km / goalKm!).clamp(0.0, 1.0).toDouble();

  double? get racesFraction => goalRaces == null
      ? null
      : (races / goalRaces!).clamp(0.0, 1.0).toDouble();

  bool get kmReached => goalKm != null && km >= goalKm!;
  bool get racesReached => goalRaces != null && races >= goalRaces!;

  /// A short line about the distance goal, or null without one.
  String? kmHint(DateTime now) {
    final g = goalKm;
    if (g == null) return null;
    if (km >= g) return 'Goal reached. Well done!';
    if (now.year != year) return '${(g - km).ceil()} km short of the goal.';
    final monthsLeft = 12 - now.month + 1;
    final perMonth = ((g - km) / monthsLeft).ceil();
    final start = DateTime(year);
    final days = DateTime(year + 1).difference(start).inDays;
    final day = DateTime(now.year, now.month, now.day).difference(start).inDays + 1;
    final ahead = km >= g * day / days;
    return '${ahead ? 'Ahead of pace. ' : ''}About $perMonth km a month '
        'for the rest of the year.';
  }

  /// A short line about the races goal, or null without one.
  String? racesHint() {
    final g = goalRaces;
    if (g == null) return null;
    if (races >= g) return 'Goal reached. Well done!';
    final left = g - races;
    final plan = plannedLeft > 0
        ? ' $plannedLeft already planned.'
        : '';
    return '$left more race${left == 1 ? '' : 's'} to go.$plan';
  }
}

GoalProgress goalProgress(
  List<Race> races,
  int year, {
  int? goalKm,
  int? goalRaces,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  var km = 0.0;
  var done = 0;
  var planned = 0;
  for (final r in races) {
    if (r.date.year != year) continue;
    if (r.status == RaceStatus.completed) {
      done++;
      km += r.distanceKm ?? 0;
    } else if (r.status == RaceStatus.planned &&
        !DateTime(r.date.year, r.date.month, r.date.day).isBefore(today)) {
      planned++;
    }
  }
  return GoalProgress(
    year: year,
    km: km,
    races: done,
    plannedLeft: planned,
    goalKm: goalKm,
    goalRaces: goalRaces,
  );
}

/// The badge closest to being earned (by its "have / need" progress), or null
/// when there is none in progress.
BadgeResult? nextBadge(List<Race> races) {
  final re = RegExp(r'^(\d+) / (\d+)');
  BadgeResult? best;
  var bestRatio = -1.0;
  for (final b in computeBadges(races)) {
    if (b.earned || b.progress == null) continue;
    final m = re.firstMatch(b.progress!);
    if (m == null) continue;
    final need = int.parse(m.group(2)!);
    if (need == 0) continue;
    final ratio = int.parse(m.group(1)!) / need;
    if (ratio > bestRatio) {
      bestRatio = ratio;
      best = b;
    }
  }
  return best;
}

/// The goals a runner set for one year.
class YearGoal {
  final int year;
  final int? km;
  final int? races;
  const YearGoal(this.year, {this.km, this.races});

  bool get isEmpty => km == null && races == null;
}

/// The most recent year before [year] that had a goal, or null.
YearGoal? latestGoalBefore(Map<int, YearGoal> goals, int year) {
  YearGoal? best;
  for (final g in goals.values) {
    if (g.year < year && !g.isEmpty && (best == null || g.year > best.year)) {
      best = g;
    }
  }
  return best;
}

/// True when this year has no goal yet but an earlier year did, so the app
/// can offer to set (or keep) goals for the new year.
bool needsNewYearPrompt(Map<int, YearGoal> goals, DateTime now) {
  final current = goals[now.year];
  if (current != null && !current.isEmpty) return false;
  return latestGoalBefore(goals, now.year) != null;
}

/// A one-line result for a past year, such as "12 / 12 races, 480 / 500 km".
String yearResult(GoalProgress g) {
  final parts = <String>[];
  if (g.goalRaces != null) parts.add('${g.races} / ${g.goalRaces} races');
  if (g.goalKm != null) {
    parts.add('${formatNumber(toUnit(g.km))} / ${formatDistance(g.goalKm!.toDouble())}');
  }
  return parts.join(', ');
}

/// Whether every goal set for that year was reached.
bool yearAchieved(GoalProgress g) {
  final any = g.goalKm != null || g.goalRaces != null;
  return any &&
      (g.goalKm == null || g.kmReached) &&
      (g.goalRaces == null || g.racesReached);
}

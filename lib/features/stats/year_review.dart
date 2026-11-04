import '../map/places.dart';
import '../races/race.dart';

/// A runner's year in numbers, from completed races dated in that year.
class YearSummary {
  final int year;
  final int races;
  final double km;
  final int totalSeconds;
  final int towns;
  final int provinces;
  final Race? longest;
  final Race? fastestPace;
  final int? busiestMonth; // 1-12
  final int busiestMonthRaces;
  final Map<String, int> pbs; // label -> seconds, e.g. '10K' -> 2999

  const YearSummary({
    required this.year,
    required this.races,
    required this.km,
    required this.totalSeconds,
    required this.towns,
    required this.provinces,
    required this.longest,
    required this.fastestPace,
    required this.busiestMonth,
    required this.busiestMonthRaces,
    required this.pbs,
  });
}

/// Years that have at least one completed race, newest first.
List<int> yearsWithRaces(List<Race> races) {
  final ys = {
    for (final r in races)
      if (r.status == RaceStatus.completed) r.date.year
  }.toList()
    ..sort((a, b) => b.compareTo(a));
  return ys;
}

YearSummary summarize(List<Race> races, int year) {
  final done = races
      .where((r) => r.status == RaceStatus.completed && r.date.year == year)
      .toList();
  var km = 0.0;
  var secs = 0;
  final towns = <String>{};
  final provinces = <String>{};
  final perMonth = <int, int>{};
  Race? longest;
  Race? fastest;
  double? fastestPace;
  final pbs = <String, int>{};

  void pb(String label, double? d, int? t, double lo, double hi) {
    if (d == null || t == null || t <= 0 || d < lo || d > hi) return;
    final cur = pbs[label];
    if (cur == null || t < cur) pbs[label] = t;
  }

  for (final r in done) {
    km += r.distanceKm ?? 0;
    secs += r.finishTimeSeconds ?? 0;
    final name = r.locationName?.trim();
    if (name != null && name.isNotEmpty) {
      towns.add(name.toLowerCase());
      final p = placeForRace(r);
      if (p != null && p.province.isNotEmpty) {
        provinces.add('${p.country}|${p.province}');
      }
    }
    perMonth[r.date.month] = (perMonth[r.date.month] ?? 0) + 1;
    if (r.distanceKm != null &&
        (longest == null || r.distanceKm! > (longest.distanceKm ?? 0))) {
      longest = r;
    }
    final d = r.distanceKm, t = r.finishTimeSeconds;
    // Pace only counts for races of 5 km or more, so a short fun run
    // does not win.
    if (d != null && d >= 5 && t != null && t > 0) {
      final pace = t / d;
      if (fastestPace == null || pace < fastestPace) {
        fastestPace = pace;
        fastest = r;
      }
    }
    pb('5K', d, t, 4.9, 5.2);
    pb('10K', d, t, 9.8, 10.5);
    pb('21K', d, t, 20.9, 21.5);
    pb('42K', d, t, 42.0, 42.6);
  }

  int? busiest;
  var busiestN = 0;
  perMonth.forEach((m, n) {
    if (n > busiestN) {
      busiest = m;
      busiestN = n;
    }
  });

  return YearSummary(
    year: year,
    races: done.length,
    km: km,
    totalSeconds: secs,
    towns: towns.length,
    provinces: provinces.length,
    longest: longest,
    fastestPace: fastest,
    busiestMonth: busiest,
    busiestMonthRaces: busiestN,
    pbs: pbs,
  );
}

import '../races/race.dart';

/// Card categories, lowest first.
enum CardTier { novice, rookie, club, competitor, veteran, master, elite }

/// Rating needed to enter each category.
const tierStarts = <CardTier, int>{
  CardTier.novice: 0,
  CardTier.rookie: 80,
  CardTier.club: 180,
  CardTier.competitor: 300,
  CardTier.veteran: 450,
  CardTier.master: 650,
  CardTier.elite: 850,
};

const _capRaces = 250;
const _capKm = 200;
const _capTowns = 100;
const _capMedals = 120;
const _capCountries = 80;
const _capImprovement = 250;

/// Numbers shown on the runner card, worked out from completed races.
class RunnerStats {
  final int completed;
  final double totalKm;
  final int towns;
  final int countries;
  final int golds;
  final int silvers;
  final int bronzes;

  /// Points earned by getting faster (0-250), see [computeStats].
  final int improvement;
  final int? pb5k; // personal bests in seconds
  final int? pb10k;
  final int? pb21k;
  final int? pb42k;

  const RunnerStats({
    required this.completed,
    required this.totalKm,
    required this.towns,
    this.countries = 0,
    this.golds = 0,
    this.silvers = 0,
    this.bronzes = 0,
    this.improvement = 0,
    this.pb5k,
    this.pb10k,
    this.pb21k,
    this.pb42k,
  });

  /// Overall rating, 0-1000. It is built slowly on purpose, so Elite takes
  /// years of racing:
  ///  - 6 per finished race (up to 250),
  ///  - 1 per 8 km raced (up to 200),
  ///  - 4 per different town (up to 100),
  ///  - medals: gold 10, silver 6, bronze 4 (up to 120),
  ///  - 10 per country (up to 80),
  ///  - improvement: getting faster than your own earlier races (up to 250).
  int get rating {
    final r = completed * 6 > _capRaces ? _capRaces : completed * 6;
    final km = (totalKm ~/ 8) > _capKm ? _capKm : (totalKm ~/ 8);
    final t = towns * 4 > _capTowns ? _capTowns : towns * 4;
    final m = golds * 10 + silvers * 6 + bronzes * 4;
    final c = countries * 10;
    final total = r +
        km +
        t +
        (m > _capMedals ? _capMedals : m) +
        (c > _capCountries ? _capCountries : c) +
        (improvement > _capImprovement ? _capImprovement : improvement);
    return total.clamp(0, 1000);
  }

  CardTier get tier {
    final r = rating;
    var best = CardTier.novice;
    for (final e in tierStarts.entries) {
      if (r >= e.value) best = e.key;
    }
    return best;
  }

  /// Points still needed for the next category, or null at the top.
  int? get pointsToNext {
    final i = tier.index;
    if (i >= CardTier.values.length - 1) return null;
    return tierStarts[CardTier.values[i + 1]]! - rating;
  }
}

RunnerStats computeStats(List<Race> races) {
  final done = races.where((r) => r.status == RaceStatus.completed).toList();
  var km = 0.0;
  final towns = <String>{};
  int? b5, b10, b21, b42;

  int? better(int? current, int? candidate) {
    if (candidate == null) return current;
    if (current == null || candidate < current) return candidate;
    return current;
  }

  var golds = 0, silvers = 0, bronzes = 0;
  final countries = <String>{};
  // Finished, timed races per distance class, to measure improvement.
  final byClass = <int, List<Race>>{};

  for (final r in done) {
    km += r.distanceKm ?? 0;
    switch (r.medal) {
      case 'gold':
        golds++;
      case 'silver':
        silvers++;
      case 'bronze':
        bronzes++;
    }
    final country = r.country?.trim().toLowerCase();
    if (country != null && country.isNotEmpty) countries.add(country);
    final cls = distanceClass(r.distanceKm);
    if (cls != null && (r.finishTimeSeconds ?? 0) > 0) {
      byClass.putIfAbsent(cls, () => []).add(r);
    }
    final town = r.locationName?.trim().toLowerCase();
    if (town != null && town.isNotEmpty) towns.add(town);

    final d = r.distanceKm;
    final t = r.finishTimeSeconds;
    if (d == null || t == null || t <= 0) continue;
    if (d >= 4.9 && d <= 5.2) {
      b5 = better(b5, t);
    } else if (d >= 9.8 && d <= 10.5) {
      b10 = better(b10, t);
    } else if (d >= 20.9 && d <= 21.5) {
      b21 = better(b21, t);
    } else if (d >= 42.0 && d <= 42.6) {
      b42 = better(b42, t);
    }
  }

  return RunnerStats(
    completed: done.length,
    totalKm: km,
    towns: towns.length,
    countries: countries.length,
    golds: golds,
    silvers: silvers,
    bronzes: bronzes,
    improvement: improvementPoints(byClass.values),
    pb5k: b5,
    pb10k: b10,
    pb21k: b21,
    pb42k: b42,
  );
}

/// 5, 10, 21 or 42 for the standard race distances, otherwise null.
int? distanceClass(double? d) {
  if (d == null) return null;
  if (d >= 4.9 && d <= 5.2) return 5;
  if (d >= 9.8 && d <= 10.5) return 10;
  if (d >= 20.9 && d <= 21.5) return 21;
  if (d >= 42.0 && d <= 42.6) return 42;
  return null;
}

/// Improvement points (0-250) from a runner's own history, so a slower runner
/// can earn as much as a fast one by getting better.
///  - Per distance (5, 10, 21, 42 km): how much the best time beats the first
///    time, up to 40 points for being 20% faster.
///  - Per season: 10 points each time a year's best at a distance beats every
///    earlier year (up to 90), so it takes seasons of progress.
int improvementPoints(Iterable<List<Race>> racesByClass) {
  var gain = 0.0;
  var seasons = 0;
  for (final races in racesByClass) {
    final sorted = [...races]..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length < 2) continue;
    final first = sorted.first.finishTimeSeconds!;
    final best = sorted
        .map((r) => r.finishTimeSeconds!)
        .reduce((a, b) => a < b ? a : b);
    final fraction = (first - best) / first;
    gain += (fraction / 0.20).clamp(0.0, 1.0) * 40;

    final bestByYear = <int, int>{};
    for (final r in sorted) {
      final y = r.date.year;
      final t = r.finishTimeSeconds!;
      if (!bestByYear.containsKey(y) || t < bestByYear[y]!) bestByYear[y] = t;
    }
    int? running;
    for (final y in bestByYear.keys.toList()..sort()) {
      final t = bestByYear[y]!;
      if (running != null && t < running) seasons++;
      if (running == null || t < running) running = t;
    }
  }
  final total = gain.round() + (seasons * 10 > 90 ? 90 : seasons * 10);
  return total > _capImprovement ? _capImprovement : total;
}

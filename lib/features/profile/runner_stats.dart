import '../races/race.dart';

enum CardTier { bronze, silver, gold, elite }

/// Numbers shown on the runner card, worked out from completed races.
class RunnerStats {
  final int completed;
  final double totalKm;
  final int towns;
  final int? pb5k; // personal bests in seconds
  final int? pb10k;
  final int? pb21k;
  final int? pb42k;

  const RunnerStats({
    required this.completed,
    required this.totalKm,
    required this.towns,
    this.pb5k,
    this.pb10k,
    this.pb21k,
    this.pb42k,
  });

  /// Overall card rating, 45-99: a base of 45, +2 per completed race,
  /// +1 per 15 km raced and +1 per different town raced in.
  int get rating {
    final r = 45 + completed * 2 + (totalKm / 15).floor() + towns;
    return r.clamp(45, 99);
  }

  CardTier get tier {
    final r = rating;
    if (r < 60) return CardTier.bronze;
    if (r < 75) return CardTier.silver;
    if (r < 90) return CardTier.gold;
    return CardTier.elite;
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

  for (final r in done) {
    km += r.distanceKm ?? 0;
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
    pb5k: b5,
    pb10k: b10,
    pb21k: b21,
    pb42k: b42,
  );
}

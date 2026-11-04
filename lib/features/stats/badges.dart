import 'package:flutter/material.dart';

import '../map/places.dart';
import '../races/race.dart';

/// One badge a runner can earn.
class RunnerBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  const RunnerBadge(this.id, this.title, this.description, this.icon, this.color);
}

/// A badge together with whether it has been earned and the progress to it.
class BadgeResult {
  final RunnerBadge badge;
  final bool earned;
  final String? progress; // e.g. "3 / 5"
  const BadgeResult(this.badge, this.earned, [this.progress]);
}

bool _near(double? km, double lo, double hi) =>
    km != null && km >= lo && km <= hi;

/// Works out every badge from the runner's races. Only completed races count.
List<BadgeResult> computeBadges(List<Race> races) {
  final done = races.where((r) => r.status == RaceStatus.completed).toList();
  final km = done.fold<double>(0, (s, r) => s + (r.distanceKm ?? 0));
  final towns = <String>{};
  final provinces = <String>{};
  for (final r in done) {
    final name = r.locationName?.trim();
    if (name != null && name.isNotEmpty) {
      towns.add(name.toLowerCase());
      final p = placeByName(name)?.province;
      if (p != null) provinces.add(p);
    }
  }

  bool any(bool Function(Race r) test) => done.any(test);
  bool under(double lo, double hi, int seconds) => any((r) =>
      _near(r.distanceKm, lo, hi) &&
      r.finishTimeSeconds != null &&
      r.finishTimeSeconds! > 0 &&
      r.finishTimeSeconds! < seconds);
  bool named(String s) =>
      any((r) => r.name.toLowerCase().contains(s));

  BadgeResult count(RunnerBadge b, num have, num need, {String unit = ''}) {
    final shown = have > need ? need : have;
    final fmt = shown % 1 == 0 ? shown.toInt().toString() : shown.toStringAsFixed(0);
    return BadgeResult(b, have >= need, '$fmt / ${need.toInt()}$unit');
  }

  const gold = Color(0xFFFFA000);
  const green = Color(0xFF00B35C);
  const blue = Color(0xFF1E6BFF);
  const purple = Color(0xFF8A3FFC);
  const red = Color(0xFFFF3D57);

  return [
    count(const RunnerBadge('first', 'First finish', 'Complete your first race',
        Icons.flag, green), done.length, 1),
    count(const RunnerBadge('races5', 'High five', 'Complete 5 races',
        Icons.looks_5, green), done.length, 5),
    count(const RunnerBadge('races10', 'Regular', 'Complete 10 races',
        Icons.directions_run, green), done.length, 10),
    count(const RunnerBadge('races25', 'Race addict', 'Complete 25 races',
        Icons.local_fire_department, gold), done.length, 25),
    count(const RunnerBadge('races50', 'Legend', 'Complete 50 races',
        Icons.emoji_events, gold), done.length, 50),
    count(const RunnerBadge('km100', '100 km club', 'Race 100 km in total',
        Icons.route, blue), km, 100, unit: ' km'),
    count(const RunnerBadge('km500', '500 km club', 'Race 500 km in total',
        Icons.route, blue), km, 500, unit: ' km'),
    count(const RunnerBadge('km1000', '1000 km club', 'Race 1,000 km in total',
        Icons.rocket_launch, purple), km, 1000, unit: ' km'),
    BadgeResult(
        const RunnerBadge('first10k', 'First 10K', 'Finish a 10 km race',
            Icons.looks_one, green),
        any((r) => _near(r.distanceKm, 9.5, 10.5))),
    BadgeResult(
        const RunnerBadge('firsthalf', 'Half hero', 'Finish a half marathon',
            Icons.star_half, blue),
        any((r) => _near(r.distanceKm, 20.0, 22.0))),
    BadgeResult(
        const RunnerBadge('firstmarathon', 'Marathoner', 'Finish a marathon',
            Icons.military_tech, gold),
        any((r) => _near(r.distanceKm, 41.0, 43.0))),
    BadgeResult(
        const RunnerBadge('ultra', 'Ultra runner',
            'Finish a race longer than a marathon', Icons.terrain, purple),
        any((r) => (r.distanceKm ?? 0) > 43.5)),
    BadgeResult(
        const RunnerBadge('sub60', 'Sub-60 10K', 'Run a 10K in under an hour',
            Icons.timer, red),
        under(9.5, 10.5, 3600)),
    BadgeResult(
        const RunnerBadge('sub2', 'Sub-2 half', 'Run a half marathon in under 2 hours',
            Icons.timer, red),
        under(20.0, 22.0, 7200)),
    BadgeResult(
        const RunnerBadge('sub4', 'Sub-4 marathon', 'Run a marathon in under 4 hours',
            Icons.timer, red),
        under(41.0, 43.0, 14400)),
    count(const RunnerBadge('towns5', 'Explorer', 'Race in 5 different towns',
        Icons.explore, blue), towns.length, 5),
    count(const RunnerBadge('towns10', 'Globetrotter', 'Race in 10 different towns',
        Icons.public, purple), towns.length, 10),
    count(const RunnerBadge('prov3', 'Road tripper', 'Race in 3 provinces',
        Icons.map, blue), provinces.length, 3),
    count(const RunnerBadge('prov5', 'Nationwide', 'Race in 5 provinces',
        Icons.flag_circle, purple), provinces.length, 5),
    BadgeResult(
        const RunnerBadge('comrades', 'Comrades finisher',
            'Finish the Comrades Marathon', Icons.workspace_premium, gold),
        named('comrades')),
    BadgeResult(
        const RunnerBadge('twooceans', 'Two Oceans finisher',
            'Finish a Two Oceans race', Icons.waves, blue),
        named('two oceans')),
  ];
}

import 'dart:math' as math;
import 'dart:ui';

import '../races/race.dart';

/// A race placed on the trail.
class TrailPoint {
  final Race race;
  final Offset pos;
  const TrailPoint(this.race, this.pos);

  /// Completed and did-not-finish races count as "passed" on the trail.
  bool get passed =>
      race.status == RaceStatus.completed || race.status == RaceStatus.dnf;
}

class TrailLayout {
  final double width;
  final double height;
  final Offset start;
  final List<TrailPoint> points; // oldest first (bottom of screen)
  const TrailLayout(this.width, this.height, this.start, this.points);
}

/// Places races (oldest first) along a winding path that runs from the
/// bottom of the screen (the start) upwards.
TrailLayout layoutTrail(
  List<Race> racesOldestFirst,
  double width,
  double viewportHeight, {
  double spacing = 170,
  double padTop = 140,
  double padBottom = 130,
}) {
  final n = racesOldestFirst.length;
  final needed = padTop + padBottom + (n > 1 ? (n - 1) * spacing : 0);
  final height = math.max(viewportHeight, needed);
  final start = Offset(width / 2, height - 40);
  final points = <TrailPoint>[];
  for (var i = 0; i < n; i++) {
    final x = width * (0.5 + 0.26 * math.sin(i * 1.3 + 0.5));
    final y = height - padBottom - i * spacing;
    points.add(TrailPoint(racesOldestFirst[i], Offset(x, y)));
  }
  return TrailLayout(width, height, start, points);
}

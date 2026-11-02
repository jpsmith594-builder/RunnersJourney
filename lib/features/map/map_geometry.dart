import 'dart:math' as math;
import 'dart:ui';

import '../races/race.dart';
import 'places.dart';

/// All of a runner's races in one town.
class RaceGroup {
  final Place place;
  final List<Race> races;
  RaceGroup(this.place, this.races);
}

class GroupResult {
  final List<RaceGroup> groups;

  /// Races whose location isn't a known town, so they can't be placed.
  final List<Race> unplaced;
  const GroupResult(this.groups, this.unplaced);
}

GroupResult groupRaces(List<Race> races) {
  final byPlace = <String, RaceGroup>{};
  final unplaced = <Race>[];
  for (final r in races) {
    final p = placeByName(r.locationName);
    if (p == null) {
      unplaced.add(r);
      continue;
    }
    byPlace.putIfAbsent(p.name, () => RaceGroup(p, [])).races.add(r);
  }
  return GroupResult(byPlace.values.toList(), unplaced);
}

/// Town groups that overlap on screen at the current zoom, merged into one pin.
class MapCluster {
  final List<RaceGroup> groups = [];
  Offset center;
  MapCluster(this.center);

  int get count => groups.fold(0, (sum, g) => sum + g.races.length);
  List<Race> get races => [for (final g in groups) ...g.races];
}

/// Greedy screen-space clustering. [toScreen] maps a place to its current
/// screen position; groups closer than [radius] pixels share a cluster.
List<MapCluster> clusterGroups(
  List<RaceGroup> groups,
  Offset Function(Place) toScreen,
  double radius,
) {
  final sorted = [...groups]
    ..sort((a, b) => b.races.length.compareTo(a.races.length));
  final clusters = <MapCluster>[];
  for (final g in sorted) {
    final s = toScreen(g.place);
    MapCluster? hit;
    for (final c in clusters) {
      if ((c.center - s).distance <= radius) {
        hit = c;
        break;
      }
    }
    if (hit == null) {
      final c = MapCluster(s);
      c.groups.add(g);
      clusters.add(c);
    } else {
      final n = hit.count;
      final m = g.races.length;
      hit.center = Offset(
        (hit.center.dx * n + s.dx * m) / (n + m),
        (hit.center.dy * n + s.dy * m) / (n + m),
      );
      hit.groups.add(g);
    }
  }
  return clusters;
}

/// Screen offsets that spread [n] pins evenly on a ring around a town, used
/// when the runner zooms in on a town with several races.
List<Offset> fanOffsets(int n, {double minRadius = 34, double perPin = 44}) {
  if (n <= 0) return const [];
  final r = math.max(minRadius, n * perPin / (2 * math.pi));
  return [
    for (var i = 0; i < n; i++)
      Offset(
        r * math.cos(-math.pi / 2 + 2 * math.pi * i / n),
        r * math.sin(-math.pi / 2 + 2 * math.pi * i / n),
      ),
  ];
}

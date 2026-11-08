import '../../core/units.dart';

/// A well-known South African race in the built-in calendar.
///
/// Dates change every year, so only the usual time of year is kept. Always
/// check the race's official site for this year's date and route.
class RaceEvent {
  final String name;
  final String? town; // must match a place name so it can go on the map
  final double distanceKm;
  final String when; // usual timing, as text
  final int? month; // 1-12 when the usual month is reliable
  final String? note;

  const RaceEvent(this.name, this.town, this.distanceKm, this.when,
      {this.month, this.note});

  String get distanceLabel {
    final d = distanceKm;
    return formatDistance(d);
  }

  /// Next time the usual month comes round (first of that month), or null.
  DateTime? nextDate([DateTime? now]) {
    final m = month;
    if (m == null) return null;
    final n = now ?? DateTime.now();
    var d = DateTime(n.year, m, 1);
    if (d.isBefore(DateTime(n.year, n.month, 1))) d = DateTime(n.year + 1, m, 1);
    return d;
  }
}

/// Starter list. Add more here (or tell the developer) as you find them.
const List<RaceEvent> kRaceEvents = [
  RaceEvent('Comrades Marathon', 'Pietermaritzburg', 88, 'June',
      month: 6,
      note: 'Durban and Pietermaritzburg; about 87 to 90 km, up or down run'),
  RaceEvent('Two Oceans Ultra Marathon', 'Cape Town', 56, 'Easter weekend',
      note: 'Easter Saturday'),
  RaceEvent('Two Oceans Half Marathon', 'Cape Town', 21.1, 'Easter weekend',
      note: 'Easter Friday'),
  RaceEvent('Cape Town Marathon', 'Cape Town', 42.2, 'October', month: 10),
  RaceEvent('Soweto Marathon', 'Soweto', 42.2, 'November', month: 11),
  RaceEvent('Soweto Half Marathon', 'Soweto', 21.1, 'November', month: 11),
  RaceEvent('Knysna Forest Marathon', 'Knysna', 42.2, 'Winter',
      note: 'Check the date'),
  RaceEvent('Otter African Trail Run', "Nature's Valley", 42, 'Spring',
      note: "Nature's Valley to Storms River; check the date"),
  RaceEvent('Ultra-Trail Cape Town 100K', 'Cape Town', 100, 'Nov / Dec',
      note: 'Also 65, 35 and 20 km options; check the date'),
  RaceEvent('parkrun', null, 5, 'Every Saturday morning',
      note: 'Free weekly 5 km at many venues'),
];

/// Calendar races whose name contains [query] (prefix matches first).
List<RaceEvent> searchEvents(String query, {int limit = 8}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final starts = <RaceEvent>[];
  final contains = <RaceEvent>[];
  for (final e in kRaceEvents) {
    final n = e.name.toLowerCase();
    if (n.startsWith(q)) {
      starts.add(e);
    } else if (n.contains(q) || (e.town ?? '').toLowerCase().startsWith(q)) {
      contains.add(e);
    }
  }
  return [...starts, ...contains].take(limit).toList();
}

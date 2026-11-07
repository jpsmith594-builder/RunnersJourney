/// A running club from the shared club list.
class Club {
  /// Null for a club the runner has typed that is not in the list yet.
  final String? id;
  final String name;
  final String area;
  final int members;

  /// How alike the typed text and this club are (0 to 1).
  final double score;

  /// True when it is the same club after ignoring capitals, dots and words
  /// such as "athletic club".
  final bool exact;

  const Club({
    this.id,
    required this.name,
    this.area = '',
    this.members = 0,
    this.score = 0,
    this.exact = false,
  });

  factory Club.fromMap(Map<String, dynamic> m) => Club(
        id: m['id'] as String?,
        name: m['name'] as String,
        area: (m['area'] as String?) ?? '',
        members: (m['members'] as num?)?.toInt() ?? 0,
        score: (m['score'] as num?)?.toDouble() ?? 0,
        exact: (m['exact'] as bool?) ?? false,
      );

  /// "Sea Point, 14 members"
  String get subtitle => [
        if (area.isNotEmpty) area,
        if (members > 0) '$members member${members == 1 ? '' : 's'}',
      ].join(', ');
}

/// What to do with the club name a runner typed, before saving it.
enum ClubDecision {
  /// Empty box: no club.
  none,

  /// Matches a club in the list (use it).
  useExisting,

  /// Looks like a club in the list: ask the runner.
  askDidYouMean,

  /// Nothing like it: add it as a new club.
  createNew,
}

/// Decides what to do with [typed] given the clubs found by the search.
/// A near match is only worth asking about when it is not the same club
/// already and is similar enough ([askAbove]).
({ClubDecision decision, Club? club}) decideClub(
  String typed,
  List<Club> found, {
  double askAbove = 0.45,
}) {
  final t = typed.trim();
  if (t.isEmpty) return (decision: ClubDecision.none, club: null);
  for (final c in found) {
    if (c.exact || c.name.toLowerCase() == t.toLowerCase()) {
      return (decision: ClubDecision.useExisting, club: c);
    }
  }
  Club? best;
  for (final c in found) {
    if (c.score >= askAbove && (best == null || c.score > best.score)) {
      best = c;
    }
  }
  if (best != null) return (decision: ClubDecision.askDidYouMean, club: best);
  return (decision: ClubDecision.createNew, club: null);
}

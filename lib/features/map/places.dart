import 'place.dart';
import 'places_data.dart';

export 'place.dart';
export 'places_data.dart';

final Map<String, Place> _byName = {
  for (final p in kPlaces) p.name.toLowerCase(): p,
};

/// Finds a place by its exact (case-insensitive) name.
Place? placeByName(String? name) {
  if (name == null) return null;
  return _byName[name.trim().toLowerCase()];
}

/// Search used by the town picker. Prefix matches rank first. With an empty
/// query the major cities are suggested.
List<Place> searchPlaces(String query, {int limit = 8}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return kPlaces.where((p) => p.tier == 1).take(limit).toList();
  }
  final starts = <Place>[];
  final contains = <Place>[];
  for (final p in kPlaces) {
    final n = p.name.toLowerCase();
    if (n.startsWith(q)) {
      starts.add(p);
    } else if (n.contains(q)) {
      contains.add(p);
    }
  }
  return [...starts, ...contains].take(limit).toList();
}

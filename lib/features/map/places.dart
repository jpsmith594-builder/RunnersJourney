import '../bucket/bucket_item.dart';
import '../races/race.dart';
import 'geo_search.dart';
import 'place.dart';
import 'places_data.dart';

export 'geo_search.dart';
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


/// A place for a saved location: its own coordinates when it has them (any town
/// in the world), otherwise the built-in list by name.
Place? placeFromSaved(String? name, double? lat, double? lng, String? region,
    String? country) {
  final n = name?.trim();
  if (n == null || n.isEmpty) return null;
  if (lat != null && lng != null) {
    final known = placeByName(n);
    return Place(
      n,
      region ?? known?.province ?? '',
      lat,
      lng,
      known?.tier ?? 3,
      country: country ?? known?.country ?? 'South Africa',
    );
  }
  return placeByName(n);
}

Place? placeForRace(Race r) =>
    placeFromSaved(r.locationName, r.lat, r.lng, r.region, r.country);

Place? placeForBucket(BucketItem b) =>
    placeFromSaved(b.locationName, b.lat, b.lng, b.region, b.country);

/// What the runner typed, resolved to a place: the one they picked if the text
/// still matches it, otherwise a built-in town with that name.
Place? resolvePlace(String typed, Place? picked) {
  final t = typed.trim();
  if (t.isEmpty) return null;
  if (picked != null && picked.name.toLowerCase() == t.toLowerCase()) {
    return picked;
  }
  return placeByName(t);
}

/// Built-in matches first, then towns from the world search, without repeats.
List<Place> mergePlaces(List<Place> local, List<Place> remote) {
  final seen = <String>{};
  return [
    for (final p in [...local, ...remote])
      if (seen.add(p.key)) p,
  ];
}

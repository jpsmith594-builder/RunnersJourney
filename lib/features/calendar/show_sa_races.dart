import '../map/places.dart';
import '../races/race.dart';

/// Whether to offer the "South African races" menu item. It is shown to
/// runners who look South African: the phone is set to South Africa, the home
/// town is a known South African town, or they already have a race there.
bool showSouthAfricanRaces({
  required List<Race> races,
  String? homeTown,
  String? localeCountry,
}) {
  if (localeCountry?.toUpperCase() == 'ZA') return true;
  final town = homeTown?.trim();
  if (town != null && town.isNotEmpty && placeByName(town) != null) {
    return true;
  }
  return races.any((r) => placeForRace(r)?.country == 'South Africa');
}

import '../map/places.dart';
import '../races/race.dart';

/// Whether to offer the "South African races" menu item. It is shown to
/// runners who look South African: the phone is set to South Africa, the home
/// town is a known South African town (when the phone does not say otherwise),
/// or they already have a race there.
bool showSouthAfricanRaces({
  required List<Race> races,
  String? homeTown,
  String? localeCountry,
}) {
  final country = localeCountry?.toUpperCase();
  if (country == 'ZA') return true;
  // A phone set to another country wins over the home-town guess: many town
  // names (Berlin, for one) exist both in South Africa and abroad.
  final phoneElsewhere = country != null && country.isNotEmpty;
  final town = homeTown?.trim();
  if (!phoneElsewhere &&
      town != null &&
      town.isNotEmpty &&
      placeByName(town) != null) {
    return true;
  }
  return races.any((r) => placeForRace(r)?.country == 'South Africa');
}

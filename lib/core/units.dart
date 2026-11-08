import 'settings.dart';

/// Kilometres in a mile.
const double kmPerMile = 1.609344;

/// Races are stored in kilometres. These helpers show them in the runner's
/// chosen unit. Every function takes an optional [miles] so tests (and code
/// that needs a fixed unit) do not depend on the saved setting.
bool _m(bool? miles) => miles ?? settings.miles;

String unitLabel({bool? miles}) => _m(miles) ? 'mi' : 'km';

/// "kilometres" or "miles".
String unitWord({bool? miles}) => _m(miles) ? 'miles' : 'kilometres';

/// A distance in kilometres, in the chosen unit.
double toUnit(double km, {bool? miles}) => _m(miles) ? km / kmPerMile : km;

/// A distance typed in the chosen unit, in kilometres.
double fromUnit(double value, {bool? miles}) =>
    _m(miles) ? value * kmPerMile : value;

/// A number for a distance: one decimal, no ".0", and no decimals from 100 up.
String formatNumber(double v) {
  if (v >= 100) return v.round().toString();
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// "10 km", "6.2 mi" from a distance in km.
String formatDistance(double km, {bool? miles}) =>
    '${formatNumber(toUnit(km, miles: miles))} ${unitLabel(miles: miles)}';

/// Pace as "m:ss /km" or "m:ss /mi" from seconds per kilometre.
String formatPaceFromSecPerKm(double secPerKm, {bool? miles}) {
  final perUnit =
      (_m(miles) ? secPerKm * kmPerMile : secPerKm).round();
  return '${paceClock(perUnit.toDouble())} /${unitLabel(miles: miles)}';
}

/// "m:ss" from seconds.
String paceClock(double seconds) {
  final s = seconds.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Seconds per kilometre turned into seconds per chosen unit (for charts).
double paceInUnit(double secPerKm, {bool? miles}) =>
    _m(miles) ? secPerKm * kmPerMile : secPerKm;

/// Common race distances, in km. Used to tidy a distance typed in miles
/// (6.2 mi becomes exactly 10 km, 13.1 mi the half marathon).
const standardKm = [5.0, 10.0, 21.0975, 42.195];

/// Rounds a kilometre value to two decimals, snapping to a standard race
/// distance when it is within 50 metres of one.
double tidyKm(double km) {
  for (final s in standardKm) {
    if ((km - s).abs() <= 0.05) return s;
  }
  return double.parse(km.toStringAsFixed(2));
}

/// A South African town, city or region that can hold races.
///
/// [fx] and [fy] are the town's position on the map artwork as fractions
/// (0..1) of its width and height. The artwork is an illustration, so these
/// are calibrated by hand / by tools/gen_places.py rather than from GPS.
class Place {
  final String name;
  final String province;
  final double lat;
  final double lng;

  /// 1 = major city, 2 = regional town, 3 = small town. Controls the zoom
  /// level at which the town's dot and label appear.
  final int tier;
  final double fx;
  final double fy;

  /// True when the artwork already prints a sign for this place.
  final bool illustrated;

  const Place(this.name, this.province, this.lat, this.lng, this.tier, this.fx,
      this.fy, this.illustrated);
}

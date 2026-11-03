/// A South African town, city, suburb or region that can hold races.
///
/// [fx] and [fy] are the place's position on the map as fractions (0..1) of its
/// width and height. They come from real latitude/longitude through the same
/// projection the artwork is drawn with (tools/mapgeo.py), so a place always
/// sits on the right spot of the picture.
class Place {
  final String name;
  final String province;
  final double lat;
  final double lng;

  /// 1 = major city, 2 = regional town, 3 = small town, 4 = Cape Town suburb,
  /// 5 = Cape Town neighbourhood. Controls the zoom level at which the dot and
  /// label appear.
  final int tier;
  final double fx;
  final double fy;

  const Place(this.name, this.province, this.lat, this.lng, this.tier, this.fx,
      this.fy);
}

/// A South African town, city, suburb or region that can hold races.
class Place {
  final String name;
  final String province;
  final double lat;
  final double lng;

  /// 1 = major city, 2 = regional town, 3 = small town, 4 = Cape Town suburb,
  /// 5 = Cape Town neighbourhood. Controls the zoom level at which the dot and
  /// label appear.
  final int tier;

  const Place(this.name, this.province, this.lat, this.lng, this.tier);
}

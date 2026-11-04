/// A town, city, suburb or region that can hold races.
class Place {
  final String name;

  /// Province, state or county.
  final String province;
  final double lat;
  final double lng;

  /// 1 = major city, 2 = regional town, 3 = small town, 4 = Cape Town suburb,
  /// 5 = Cape Town neighbourhood. Controls the zoom level at which the dot and
  /// label appear. Places found by search are tier 3.
  final int tier;
  final String country;

  const Place(this.name, this.province, this.lat, this.lng, this.tier,
      {this.country = 'South Africa'});

  /// "Western Cape, South Africa"
  String get where =>
      [if (province.isNotEmpty) province, if (country.isNotEmpty) country]
          .join(', ');

  /// Same town in the same country.
  String get key => '${name.toLowerCase()}|${country.toLowerCase()}';
}

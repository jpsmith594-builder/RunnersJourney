/// A race the runner wants to complete one day.
class BucketItem {
  final String? id;
  final String name;
  final String? locationName;
  final double? lat;
  final double? lng;
  final String? region;
  final String? country;
  final double? distanceKm;
  final bool done;

  const BucketItem({
    this.id,
    required this.name,
    this.locationName,
    this.lat,
    this.lng,
    this.region,
    this.country,
    this.distanceKm,
    this.done = false,
  });

  factory BucketItem.fromMap(Map<String, dynamic> m) => BucketItem(
        id: m['id'] as String?,
        name: m['name'] as String,
        locationName: m['location_name'] as String?,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        region: m['region'] as String?,
        country: m['country'] as String?,
        distanceKm: (m['distance_km'] as num?)?.toDouble(),
        done: (m['done'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'location_name': locationName,
        'lat': lat,
        'lng': lng,
        'region': region,
        'country': country,
        'distance_km': distanceKm,
        'done': done,
      };

  BucketItem copyWith({bool? done}) => BucketItem(
        id: id,
        name: name,
        locationName: locationName,
        lat: lat,
        lng: lng,
        region: region,
        country: country,
        distanceKm: distanceKm,
        done: done ?? this.done,
      );
}

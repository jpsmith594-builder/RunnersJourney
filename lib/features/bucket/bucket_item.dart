/// A race the runner wants to complete one day.
class BucketItem {
  final String? id;
  final String name;
  final String? locationName;
  final double? distanceKm;
  final bool done;

  const BucketItem({
    this.id,
    required this.name,
    this.locationName,
    this.distanceKm,
    this.done = false,
  });

  factory BucketItem.fromMap(Map<String, dynamic> m) => BucketItem(
        id: m['id'] as String?,
        name: m['name'] as String,
        locationName: m['location_name'] as String?,
        distanceKm: (m['distance_km'] as num?)?.toDouble(),
        done: (m['done'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'location_name': locationName,
        'distance_km': distanceKm,
        'done': done,
      };

  BucketItem copyWith({bool? done}) => BucketItem(
        id: id,
        name: name,
        locationName: locationName,
        distanceKm: distanceKm,
        done: done ?? this.done,
      );
}

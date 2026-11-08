import '../../core/units.dart';

enum RaceStatus { planned, completed, dnf, dns }

class Race {
  final String? id;
  final String name;
  final DateTime date;
  final RaceStatus status;
  final double? distanceKm;
  final int? finishTimeSeconds;
  final int? overallPosition;
  final int? ageGroupPosition;
  final String? locationName;
  final double? lat;
  final double? lng;
  final String? region;
  final String? country;

  /// 'gold', 'silver' or 'bronze' when the runner collected a medal.
  final String? medal;
  final String? notes;

  const Race({
    this.id,
    required this.name,
    required this.date,
    required this.status,
    this.distanceKm,
    this.finishTimeSeconds,
    this.overallPosition,
    this.ageGroupPosition,
    this.locationName,
    this.lat,
    this.lng,
    this.region,
    this.country,
    this.medal,
    this.notes,
  });

  factory Race.fromMap(Map<String, dynamic> m) {
    return Race(
      id: m['id'] as String,
      name: m['name'] as String,
      date: DateTime.parse(m['race_date'] as String),
      status: RaceStatus.values.firstWhere(
        (s) => s.name == m['status'],
        orElse: () => RaceStatus.planned,
      ),
      distanceKm: (m['distance_km'] as num?)?.toDouble(),
      finishTimeSeconds: m['finish_time_seconds'] as int?,
      overallPosition: m['overall_position'] as int?,
      ageGroupPosition: m['age_group_position'] as int?,
      locationName: m['location_name'] as String?,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      region: m['region'] as String?,
      country: m['country'] as String?,
      medal: m['medal'] as String?,
      notes: m['notes'] as String?,
    );
  }

  /// Map for insert/update. user_id is added by the repository.
  Map<String, dynamic> toMap() {
    final d = date;
    final iso =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {
      'name': name,
      'race_date': iso,
      'status': status.name,
      'distance_km': distanceKm,
      'finish_time_seconds': finishTimeSeconds,
      'overall_position': overallPosition,
      'age_group_position': ageGroupPosition,
      'location_name': locationName,
      'lat': lat,
      'lng': lng,
      'region': region,
      'country': country,
      'medal': medal,
      'notes': notes,
    };
  }

  String get formattedTime => formatDuration(finishTimeSeconds);

  /// Average pace as "m:ss /km" ("/mi" in miles), or null without a
  /// distance and a time.
  String? get pace => formatPace(distanceKm, finishTimeSeconds);
}

/// Pace as "m:ss /km" (or "/mi" in miles) from a distance in km and a time in
/// seconds.
String? formatPace(double? km, int? seconds, {bool? miles}) {
  if (km == null || seconds == null || km <= 0 || seconds <= 0) return null;
  return formatPaceFromSecPerKm(seconds / km, miles: miles);
}

String formatDuration(int? seconds) {
  if (seconds == null) return '-';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Parses "h:mm:ss", "mm:ss" or plain minutes ("45"). Returns null if empty/invalid.
int? parseDuration(String input) {
  final t = input.trim();
  if (t.isEmpty) return null;
  final parts = t.split(':').map((p) => int.tryParse(p.trim())).toList();
  if (parts.any((p) => p == null || p < 0)) return null;
  final n = parts.cast<int>();
  switch (n.length) {
    case 1:
      return n[0] * 60;
    case 2:
      return n[0] * 60 + n[1];
    case 3:
      return n[0] * 3600 + n[1] * 60 + n[2];
    default:
      return null;
  }
}

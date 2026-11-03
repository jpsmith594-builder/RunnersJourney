/// A photo attached to a race. [url] is a short-lived signed link.
class RacePhoto {
  final String id;
  final String raceId;
  final String storagePath;
  final String url;

  const RacePhoto({
    required this.id,
    required this.raceId,
    required this.storagePath,
    required this.url,
  });
}

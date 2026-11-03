import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'race_photo.dart';

/// Race photos live in the private `race-photos` Storage bucket under
/// `<user_id>/<race_id>/<file>`, with one row per photo in `race_photos`.
class PhotoRepository {
  static const _bucket = 'race-photos';
  static const _urlSeconds = 3600;

  // Signed links last an hour, so keep lists for a little less than that.
  static final Map<String, ({DateTime at, List<RacePhoto> photos})> _cache = {};

  final SupabaseClient _db = Supabase.instance.client;

  Future<List<RacePhoto>> list(String raceId, {bool refresh = false}) async {
    final hit = _cache[raceId];
    if (!refresh &&
        hit != null &&
        DateTime.now().difference(hit.at) < const Duration(minutes: 45)) {
      return hit.photos;
    }
    final rows = await _db
        .from('race_photos')
        .select()
        .eq('race_id', raceId)
        .order('created_at');
    final photos = await Future.wait((rows as List).map((r) async {
      final m = r as Map<String, dynamic>;
      final path = m['storage_path'] as String;
      final url =
          await _db.storage.from(_bucket).createSignedUrl(path, _urlSeconds);
      return RacePhoto(
        id: m['id'] as String,
        raceId: raceId,
        storagePath: path,
        url: url,
      );
    }));
    _cache[raceId] = (at: DateTime.now(), photos: photos);
    return photos;
  }

  /// Uploads a (already downsized) picture and records it against the race.
  Future<void> add(String raceId, XFile file) async {
    final uid = _db.auth.currentUser!.id;
    final bytes = await file.readAsBytes();
    final isPng = file.name.toLowerCase().endsWith('.png');
    final path = '$uid/$raceId/${DateTime.now().microsecondsSinceEpoch}'
        '.${isPng ? 'png' : 'jpg'}';
    await _db.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
              contentType: isPng ? 'image/png' : 'image/jpeg', upsert: false),
        );
    await _db.from('race_photos').insert({
      'race_id': raceId,
      'user_id': uid,
      'storage_path': path,
    });
    _cache.remove(raceId);
  }

  /// Removes the stored files of a race that is being deleted (the database
  /// rows go with the race itself).
  Future<void> deleteFilesOf(String raceId) async {
    final photos = await list(raceId, refresh: true);
    if (photos.isNotEmpty) {
      await _db.storage
          .from(_bucket)
          .remove([for (final p in photos) p.storagePath]);
    }
    _cache.remove(raceId);
  }

  Future<void> delete(RacePhoto photo) async {
    await _db.storage.from(_bucket).remove([photo.storagePath]);
    await _db.from('race_photos').delete().eq('id', photo.id);
    _cache.remove(photo.raceId);
  }
}

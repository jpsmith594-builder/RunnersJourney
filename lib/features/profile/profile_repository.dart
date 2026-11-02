import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile.dart';

class ProfileRepository {
  final SupabaseClient _db = Supabase.instance.client;

  String get _uid => _db.auth.currentUser!.id;

  Future<RunnerProfile> load() async {
    final row =
        await _db.from('profiles').select().eq('id', _uid).maybeSingle();
    return row == null ? RunnerProfile.empty : RunnerProfile.fromMap(row);
  }

  /// Upsert so it also works if the profile row doesn't exist yet.
  Future<void> save(RunnerProfile p) async {
    await _db.from('profiles').upsert({'id': _uid, ...p.toMap()});
  }

  /// Uploads a new profile photo and returns its storage path.
  Future<String> uploadAvatar(XFile file) async {
    final bytes = await file.readAsBytes();
    final isPng = file.name.toLowerCase().endsWith('.png');
    final ext = isPng ? 'png' : 'jpg';
    final path = '$_uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: isPng ? 'image/png' : 'image/jpeg',
            upsert: true,
          ),
        );
    return path;
  }

  Future<void> removeAvatar(String path) async {
    await _db.storage.from('avatars').remove([path]);
  }

  Future<String?> signedAvatarUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    return _db.storage.from('avatars').createSignedUrl(path, 3600);
  }
}

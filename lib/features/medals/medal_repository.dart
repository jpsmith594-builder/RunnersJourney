import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'medal.dart';

/// Medal pictures live in the private `medal-photos` bucket under
/// `<user_id>/<file>.png`, with one row per medal in `medal_photos`.
class MedalRepository {
  static const _bucket = 'medal-photos';
  static const _urlSeconds = 3600;

  // Signed links last an hour, so keep the list for a little less than that.
  static ({DateTime at, List<Medal> medals})? _cache;

  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Medal>> list({bool refresh = false}) async {
    final hit = _cache;
    if (!refresh &&
        hit != null &&
        DateTime.now().difference(hit.at) < const Duration(minutes: 45)) {
      return hit.medals;
    }
    final rows = await _db.from('medal_photos').select().order('created_at');
    final medals = await Future.wait((rows as List).map((r) async {
      final m = r as Map<String, dynamic>;
      final path = m['storage_path'] as String;
      final url =
          await _db.storage.from(_bucket).createSignedUrl(path, _urlSeconds);
      return Medal(
        id: m['id'] as String,
        raceId: m['race_id'] as String?,
        storagePath: path,
        url: url,
        metal: metalFrom(m['metal'] as String?),
        ribbon: ribbonFrom(m['ribbon'] as String?),
        createdAt: DateTime.parse(m['created_at'] as String),
      );
    }));
    _cache = (at: DateTime.now(), medals: medals);
    return medals;
  }

  /// A friend's wall, oldest first. Empty when they keep it private.
  Future<List<Medal>> listOf(String userId) async {
    final rows = await _db
        .from('medal_photos')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return Future.wait((rows as List).map((r) async {
      final m = r as Map<String, dynamic>;
      final path = m['storage_path'] as String;
      final url =
          await _db.storage.from(_bucket).createSignedUrl(path, _urlSeconds);
      return Medal(
        id: m['id'] as String,
        raceId: m['race_id'] as String?,
        storagePath: path,
        url: url,
        metal: metalFrom(m['metal'] as String?),
        ribbon: ribbonFrom(m['ribbon'] as String?),
        createdAt: DateTime.parse(m['created_at'] as String),
      );
    }));
  }

  /// Whether friends may see the signed-in runner's wall.
  Future<bool> sharedWithFriends() async {
    final row = await _db
        .from('profiles')
        .select('medals_visible_to_friends')
        .eq('id', _db.auth.currentUser!.id)
        .maybeSingle();
    return (row?['medals_visible_to_friends'] as bool?) ?? true;
  }

  Future<void> setSharedWithFriends(bool value) async {
    await _db
        .from('profiles')
        .update({'medals_visible_to_friends': value}).eq(
            'id', _db.auth.currentUser!.id);
  }

  /// Uploads the cut-out picture and hangs a new medal on the wall.
  Future<void> add(
    Uint8List png, {
    String? raceId,
    required MedalMetal metal,
    required MedalRibbon ribbon,
  }) async {
    final uid = _db.auth.currentUser!.id;
    final path = '$uid/${DateTime.now().microsecondsSinceEpoch}.png';
    await _db.storage.from(_bucket).uploadBinary(
          path,
          png,
          fileOptions:
              const FileOptions(contentType: 'image/png', upsert: false),
        );
    try {
      await _db.from('medal_photos').insert({
        'user_id': uid,
        'race_id': raceId,
        'storage_path': path,
        'metal': metal.name,
        'ribbon': ribbon.name,
      });
    } catch (_) {
      // The row was refused (medal limit, offline...): do not leave the
      // uploaded file behind with nothing pointing at it.
      try {
        await _db.storage.from(_bucket).remove([path]);
      } catch (_) {}
      rethrow;
    }
    _cache = null;
  }

  /// Changes a medal. Give [png] to swap its picture for a new one.
  Future<void> update(
    Medal medal, {
    String? raceId,
    required MedalMetal metal,
    required MedalRibbon ribbon,
    Uint8List? png,
  }) async {
    String? newPath;
    if (png != null) {
      final uid = _db.auth.currentUser!.id;
      newPath = '$uid/${DateTime.now().microsecondsSinceEpoch}.png';
      await _db.storage.from(_bucket).uploadBinary(
            newPath,
            png,
            fileOptions:
                const FileOptions(contentType: 'image/png', upsert: false),
          );
    }
    try {
      await _db.from('medal_photos').update({
        'race_id': raceId,
        'metal': metal.name,
        'ribbon': ribbon.name,
        if (newPath != null) 'storage_path': newPath,
      }).eq('id', medal.id);
    } catch (_) {
      if (newPath != null) {
        try {
          await _db.storage.from(_bucket).remove([newPath]);
        } catch (_) {}
      }
      rethrow;
    }
    if (newPath != null) {
      // The old picture is no longer used.
      try {
        await _db.storage.from(_bucket).remove([medal.storagePath]);
      } catch (_) {}
    }
    _cache = null;
  }

  Future<void> delete(Medal medal) async {
    await _db.storage.from(_bucket).remove([medal.storagePath]);
    await _db.from('medal_photos').delete().eq('id', medal.id);
    _cache = null;
  }
}

import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Account-level actions.
class AccountRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// Deletes the runner's photo files, then the account itself (the database
  /// removes every row that belongs to them), then signs out.
  Future<void> deleteAccount() async {
    final uid = _db.auth.currentUser!.id;

    // Files first: the database cannot remove them. Best effort, so a storage
    // hiccup never stops someone from deleting their account.
    try {
      final rows = await _db.from('race_photos').select('storage_path');
      final paths = [for (final r in rows as List) r['storage_path'] as String];
      for (var i = 0; i < paths.length; i += 100) {
        await _db.storage
            .from('race-photos')
            .remove(paths.sublist(i, math.min(i + 100, paths.length)));
      }
      final medalRows = await _db.from('medal_photos').select('storage_path');
      final medalPaths = [
        for (final r in medalRows as List) r['storage_path'] as String
      ];
      for (var i = 0; i < medalPaths.length; i += 100) {
        await _db.storage.from('medal-photos').remove(
            medalPaths.sublist(i, math.min(i + 100, medalPaths.length)));
      }
      final prof = await _db
          .from('profiles')
          .select('avatar_path')
          .eq('id', uid)
          .maybeSingle();
      final avatar = prof?['avatar_path'] as String?;
      if (avatar != null && avatar.isNotEmpty) {
        await _db.storage.from('avatars').remove([avatar]);
      }
    } catch (_) {}

    await _db.rpc('delete_my_account');
    try {
      await _db.auth.signOut();
    } catch (_) {}
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import 'bucket_item.dart';

class BucketRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<BucketItem>> list() async {
    final rows = await _db.from('bucket_list').select().order('created_at');
    return (rows as List)
        .map((r) => BucketItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(BucketItem item) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from('bucket_list').insert({...item.toMap(), 'user_id': uid});
  }

  Future<void> update(BucketItem item) async {
    await _db.from('bucket_list').update(item.toMap()).eq('id', item.id!);
  }

  Future<void> delete(String id) async {
    await _db.from('bucket_list').delete().eq('id', id);
  }
}

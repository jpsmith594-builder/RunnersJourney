import 'package:flutter/foundation.dart';

import 'bucket_item.dart';
import 'bucket_repository.dart';
import '../../core/errors.dart';

/// Holds the runner's bucket list so the list screen and the map share it.
class BucketStore extends ChangeNotifier {
  final BucketRepository _repo = BucketRepository();

  List<BucketItem> items = [];
  bool loading = true;
  String? error;

  List<BucketItem> get open => items.where((i) => !i.done).toList();

  Future<void> load() async {
    try {
      items = await _repo.list();
      error = null;
    } catch (e) {
      error = describeError(e);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> add(BucketItem item) async {
    await _repo.add(item);
    await load();
  }

  Future<void> update(BucketItem item) async {
    await _repo.update(item);
    await load();
  }

  /// Ticks or unticks an item. The list updates straight away.
  Future<void> setDone(BucketItem item, bool done) async {
    final i = items.indexWhere((x) => x.id == item.id);
    if (i >= 0) {
      items = [...items]..[i] = item.copyWith(done: done);
      notifyListeners();
    }
    try {
      await _repo.update(item.copyWith(done: done));
    } catch (e) {
      error = describeError(e);
      await load();
    }
  }

  Future<void> delete(BucketItem item) async {
    await _repo.delete(item.id!);
    await load();
  }
}

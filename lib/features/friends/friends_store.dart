import 'package:flutter/foundation.dart';

import 'friend_entry.dart';
import 'friends_repository.dart';

/// The runner's friend code, friends and pending requests.
class FriendsStore extends ChangeNotifier {
  final FriendsRepository _repo = FriendsRepository();

  String code = '';
  List<FriendEntry> entries = [];
  bool loading = true;
  String? error;

  List<FriendEntry> get friends => entries.where((e) => e.accepted).toList();
  List<FriendEntry> get requests =>
      entries.where((e) => !e.accepted && e.incoming).toList();
  List<FriendEntry> get sent =>
      entries.where((e) => !e.accepted && !e.incoming).toList();

  Future<void> load() async {
    try {
      code = await _repo.myCode();
      entries = await _repo.list();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  /// Returns the other runner's name. Throws a readable message on failure.
  Future<String> addByCode(String code) async {
    final name = await _repo.addByCode(code);
    await load();
    return name;
  }

  Future<void> accept(FriendEntry e) async {
    await _repo.accept(e.friendshipId);
    await load();
  }

  Future<void> remove(FriendEntry e) async {
    await _repo.remove(e.friendshipId);
    await load();
  }
}

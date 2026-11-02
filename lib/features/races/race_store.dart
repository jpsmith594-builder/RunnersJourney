import 'package:flutter/foundation.dart';

import 'race.dart';
import 'race_repository.dart';

/// Holds the runner's races so the Journey and Races tabs share one list.
class RaceStore extends ChangeNotifier {
  final RaceRepository _repo = RaceRepository();

  List<Race> races = []; // oldest first
  bool loading = true;
  bool _loaded = false;
  String? error;
  bool southern = true;

  Future<void> load() async {
    if (!_loaded) {
      loading = true;
      notifyListeners();
    }
    try {
      final list = await _repo.list();
      list.sort((a, b) => a.date.compareTo(b.date));
      races = list;
      southern = await _repo.isSouthern();
      error = null;
      _loaded = true;
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> delete(Race race) async {
    await _repo.delete(race.id!);
    await load();
  }
}

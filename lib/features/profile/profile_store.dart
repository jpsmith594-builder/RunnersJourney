import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'profile.dart';
import 'profile_repository.dart';

/// Holds the runner's profile and a signed URL for their photo.
class ProfileStore extends ChangeNotifier {
  final ProfileRepository _repo = ProfileRepository();

  RunnerProfile profile = RunnerProfile.empty;
  String? avatarUrl;
  bool loading = true;
  String? error;

  Future<void> load() async {
    try {
      profile = await _repo.load();
      avatarUrl = await _repo.signedAvatarUrl(profile.avatarPath);
      error = null;
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  /// Saves the profile; uploads [newAvatar] first when one was picked.
  Future<void> save(RunnerProfile p, {XFile? newAvatar}) async {
    var path = profile.avatarPath;
    if (newAvatar != null) {
      final old = profile.avatarPath;
      path = await _repo.uploadAvatar(newAvatar);
      if (old != null) {
        try {
          await _repo.removeAvatar(old);
        } catch (_) {
          // Best effort: an orphaned old photo is harmless.
        }
      }
    }
    // Clearing the club also clears the link to the club list.
    final clearClub = profile.clubId != null && p.clubId == null;
    await _repo.save(
        RunnerProfile(
      displayName: p.displayName,
      club: p.club,
      clubId: p.clubId,
      homeTown: p.homeTown,
      favouriteDistance: p.favouriteDistance,
      avatarPath: path,
      gender: p.gender,
      birthYear: p.birthYear,
    ),
        clearClub: clearClub);
    await load();
  }
}

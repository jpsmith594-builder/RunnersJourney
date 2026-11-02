/// The runner's editable profile (stored in the `profiles` table).
class RunnerProfile {
  final String? displayName;
  final String? club;
  final String? homeTown;
  final String? favouriteDistance; // e.g. 5K, 10K, 21K, 42K, Ultra, Trail
  final String? avatarPath; // path in the private `avatars` storage bucket

  const RunnerProfile({
    this.displayName,
    this.club,
    this.homeTown,
    this.favouriteDistance,
    this.avatarPath,
  });

  static const empty = RunnerProfile();

  factory RunnerProfile.fromMap(Map<String, dynamic> m) => RunnerProfile(
        displayName: m['display_name'] as String?,
        club: m['club'] as String?,
        homeTown: m['home_town'] as String?,
        favouriteDistance: m['favourite_distance'] as String?,
        avatarPath: m['avatar_path'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'display_name': displayName,
        'club': club,
        'home_town': homeTown,
        'favourite_distance': favouriteDistance,
        'avatar_path': avatarPath,
      };
}

const List<String> kFavouriteDistances = [
  '5K',
  '10K',
  '21K',
  '42K',
  'Ultra',
  'Trail',
];

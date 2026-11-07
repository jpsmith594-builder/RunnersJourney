enum Gender { male, female, nonBinary, undisclosed }

extension GenderInfo on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.nonBinary:
        return 'Non-binary';
      case Gender.undisclosed:
        return 'Prefer not to say';
    }
  }

  /// Short code printed on the runner card (nothing for "prefer not to say").
  String? get short {
    switch (this) {
      case Gender.male:
        return 'M';
      case Gender.female:
        return 'F';
      case Gender.nonBinary:
        return 'NB';
      case Gender.undisclosed:
        return null;
    }
  }

  /// Value stored in the `profiles.gender` column.
  String get db {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.nonBinary:
        return 'non_binary';
      case Gender.undisclosed:
        return 'undisclosed';
    }
  }

  static Gender? fromDb(String? value) {
    for (final g in Gender.values) {
      if (g.db == value) return g;
    }
    return null;
  }
}

/// The runner's editable profile (stored in the `profiles` table).
class RunnerProfile {
  final String? displayName;
  final String? club;

  /// The club in the shared club list (the name above is its official name).
  final String? clubId;
  final String? homeTown;
  final String? favouriteDistance; // e.g. 5K, 10K, 21K, 42K, Ultra, Trail
  final String? avatarPath; // path in the private `avatars` storage bucket
  final Gender? gender;

  /// Stored instead of the age itself so the card's age keeps up over time.
  final int? birthYear;

  const RunnerProfile({
    this.displayName,
    this.club,
    this.clubId,
    this.homeTown,
    this.favouriteDistance,
    this.avatarPath,
    this.gender,
    this.birthYear,
  });

  static const empty = RunnerProfile();

  /// Age in years (calendar-year based, so it can be one out before the
  /// runner's birthday).
  int? ageAt(DateTime now) => birthYear == null ? null : now.year - birthYear!;

  int? get age => ageAt(DateTime.now());

  factory RunnerProfile.fromMap(Map<String, dynamic> m) => RunnerProfile(
        displayName: m['display_name'] as String?,
        club: m['club'] as String?,
        clubId: m['club_id'] as String?,
        homeTown: m['home_town'] as String?,
        favouriteDistance: m['favourite_distance'] as String?,
        avatarPath: m['avatar_path'] as String?,
        gender: GenderInfo.fromDb(m['gender'] as String?),
        birthYear: m['birth_year'] as int?,
      );

  /// [includeClubId] adds the club link, including a null to clear it.
  Map<String, dynamic> toMap({bool includeClubId = false}) => {
        'display_name': displayName,
        'club': club,
        if (includeClubId || clubId != null) 'club_id': clubId,
        'home_town': homeTown,
        'favourite_distance': favouriteDistance,
        'avatar_path': avatarPath,
        'gender': gender?.db,
        'birth_year': birthYear,
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

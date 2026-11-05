import 'package:flutter/material.dart';

import '../races/race_store.dart';
import 'edit_profile_screen.dart';
import 'profile.dart';
import 'profile_store.dart';
import 'runner_card.dart';
import 'runner_stats.dart';
import 'share_card.dart';

/// Shows the runner's football-style card with Share and Edit buttons.
class ProfileScreen extends StatefulWidget {
  final ProfileStore profileStore;
  final RaceStore raceStore;

  const ProfileScreen({
    super.key,
    required this.profileStore,
    required this.raceStore,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey _cardKey = GlobalKey();
  ProfileStore get profileStore => widget.profileStore;
  RaceStore get raceStore => widget.raceStore;

  void _share() {
    final p = profileStore.profile;
    final stats = computeStats(raceStore.races);
    final name = (p.displayName ?? '').trim();
    shareRunnerCard(
      context,
      _cardKey,
      message: '${name.isEmpty ? 'My' : '$name\'s'} My Running Journal card: '
          'rating ${stats.rating}, ${stats.completed} races, '
          '${stats.totalKm.round()} km.',
    );
  }

  void _edit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => EditProfileScreen(store: profileStore)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Runner card'),
        actions: [
          IconButton(
            tooltip: 'Share card',
            icon: const Icon(Icons.ios_share),
            onPressed: _share,
          ),
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([profileStore, raceStore]),
        builder: (context, _) {
          if (profileStore.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = profileStore.profile;
          final stats = computeStats(raceStore.races);
          final incomplete = p.avatarPath == null ||
              (p.club ?? '').isEmpty ||
              p.favouriteDistance == null ||
              p.age == null ||
              p.gender == null;
          final small = Theme.of(context).textTheme.bodySmall;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CardStage(
                      boundaryKey: _cardKey,
                      child: RunnerCard(
                        name: (p.displayName ?? '').trim().isEmpty
                            ? 'Runner'
                            : p.displayName!.trim(),
                        club: p.club,
                        homeTown: p.homeTown,
                        favouriteDistance: p.favouriteDistance,
                        genderShort: p.gender?.short,
                        age: p.age,
                        avatarUrl: profileStore.avatarUrl,
                        stats: stats,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Share my card'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Story-size picture for Instagram, Facebook, WhatsApp Status, TikTok and more',
                      style: small,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _edit(context),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(
                          incomplete ? 'Complete your card' : 'Edit profile'),
                    ),
                    if (profileStore.error != null) ...[
                      const SizedBox(height: 8),
                      Text('Could not load your profile: ${profileStore.error}',
                          style: small, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Rating starts at 45 and grows with every finished race (+2), '
                      'every 15 km raced (+1) and every new town (+1).',
                      style: small,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

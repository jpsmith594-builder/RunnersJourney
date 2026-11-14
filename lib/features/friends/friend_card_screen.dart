import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../profile/profile.dart';
import '../profile/profile_repository.dart';
import '../profile/runner_card.dart';
import '../profile/runner_stats.dart';
import '../races/race.dart';
import 'friend_entry.dart';
import 'friends_repository.dart';
import 'reactions.dart';
import '../../core/units.dart';

/// A friend's runner card and their most recent races.
class FriendCardScreen extends StatefulWidget {
  final FriendEntry entry;
  const FriendCardScreen({super.key, required this.entry});

  @override
  State<FriendCardScreen> createState() => _FriendCardScreenState();
}

class _FriendData {
  final RunnerProfile profile;
  final List<Race> races;
  final String? avatarUrl;
  const _FriendData(this.profile, this.races, this.avatarUrl);
}

class _FriendCardScreenState extends State<FriendCardScreen> {
  late final Future<_FriendData> _data = _load();

  Future<_FriendData> _load() async {
    final repo = FriendsRepository();
    final profile = await repo.profileOf(widget.entry.otherId);
    final races = await repo.racesOf(widget.entry.otherId);
    String? url;
    try {
      url = await ProfileRepository().signedAvatarUrl(profile.avatarPath);
    } catch (_) {
      url = null; // photo is optional
    }
    return _FriendData(profile, races, url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.entry.name)),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: FutureBuilder<_FriendData>(
        future: _data,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load this runner.\n${snap.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          final d = snap.data!;
          final p = d.profile;
          final stats = computeStats(d.races);
          final recent = d.races
              .where((r) => r.status == RaceStatus.completed)
              .toList()
              .reversed
              .take(8)
              .toList();
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RunnerCard(
                      name: (p.displayName ?? '').trim().isEmpty
                          ? widget.entry.name
                          : p.displayName!.trim(),
                      club: p.club,
                      homeTown: p.homeTown,
                      favouriteDistance: p.favouriteDistance,
                      genderShort: p.gender?.short,
                      age: p.age,
                      avatarUrl: d.avatarUrl,
                      stats: stats,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Recent races',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    if (recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('No completed races yet.')),
                      ),
                    for (final r in recent)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading:
                                const Icon(Icons.flag, color: Colors.green),
                            title: Text(r.name),
                            subtitle: Text([
                              DateFormat.yMMMd().format(r.date),
                              if (r.distanceKm != null) formatDistance(r.distanceKm!),
                              if (r.finishTimeSeconds != null) r.formattedTime,
                              if (r.pace != null) r.pace!,
                            ].join(' \u00B7 ')),
                          ),
                          if (r.id != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 4, bottom: 4),
                              child:
                                  ReactionsBar(raceId: r.id!, canReact: true),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

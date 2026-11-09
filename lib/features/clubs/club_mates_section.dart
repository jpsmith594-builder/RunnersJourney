import 'package:flutter/material.dart';

import '../../core/tiles.dart';
import 'club_mates.dart';
import '../../core/errors.dart';

/// "People from my club" on the Friends screen, with the opt-in switch.
class ClubMatesSection extends StatelessWidget {
  final ClubMatesStore store;
  final String? clubName;

  /// Called after a request is sent or accepted, so the friends list updates.
  final VoidCallback onFriendsChanged;

  const ClubMatesSection({
    super.key,
    required this.store,
    required this.clubName,
    required this.onFriendsChanged,
  });

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _toggle(BuildContext context, bool on) async {
    try {
      await store.setVisible(on);
    } catch (e) {
      if (context.mounted) {
        _toast(context,
            'Could not change this: $e\n(Have you run supabase/018_club_mates.sql?)');
      }
    }
  }

  Future<void> _add(BuildContext context, ClubMate m) async {
    try {
      final name = await store.add(m);
      onFriendsChanged();
      if (context.mounted) {
        _toast(
            context,
            m.status == 'pending_in'
                ? 'You and $name are now friends.'
                : 'Request sent to $name.');
      }
    } catch (e) {
      if (context.mounted) _toast(context, failMessage('Could not add', e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final club = (clubName ?? '').trim();
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        // No club on the profile yet.
        if (club.isEmpty || (!store.hasClub && !store.loading)) {
          return SoftCard(
            margin: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                const Icon(Icons.groups_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Add your running club in Edit profile to find people '
                      'from your club here.',
                      style: t.bodyMedium),
                ),
              ],
            ),
          );
        }
        if (store.error != null && !store.loading) {
          return const SizedBox.shrink();
        }
        return SoftCard(
          margin: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('People from $club',
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: store.visible,
                onChanged: store.loading ? null : (v) => _toggle(context, v),
                title: const Text('Let people from my club find me'),
                subtitle: const Text(
                    'Club-mates who also switch this on can see your name and '
                    'send you a friend request. Your races, photos and runner '
                    'card stay private until you accept.'),
              ),
              if (store.visible) ...[
                const Divider(),
                if (store.mates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                        'No club-mates have switched this on yet. Invite them '
                        'with your friend code.',
                        style: t.bodyMedium),
                  ),
                for (final m in store.mates)
                  Builder(builder: (context) {
                    final a = clubMateAction(m.status);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                          child: Text(m.name.isEmpty
                              ? 'R'
                              : m.name[0].toUpperCase())),
                      title: Text(m.name),
                      trailing: m.status == 'friends'
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : OutlinedButton(
                              onPressed:
                                  a.enabled ? () => _add(context, m) : null,
                              child: Text(a.label),
                            ),
                    );
                  }),
              ],
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../races/race_store.dart';
import '../../core/theme.dart';
import '../../core/tiles.dart';
import 'badges.dart';
import 'crest.dart';

/// All badges as crests: earned ones shine, locked ones are grey with progress.
class BadgesScreen extends StatelessWidget {
  final RaceStore store;
  const BadgesScreen({super.key, required this.store});

  void _show(BuildContext context, BadgeResult b) {
    final tier = crestTierOf(b.badge.id);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Crest(badge: b.badge, earned: b.earned, size: 150),
            const SizedBox(height: 12),
            Text(tier.label,
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                    color: b.earned ? tier.metal[2] : Colors.grey)),
            const SizedBox(height: 4),
            Text(b.badge.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(b.badge.description, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            if (b.earned)
              const Text('Earned!',
                  style: TextStyle(
                      color: Color(0xFF00B35C),
                      fontWeight: FontWeight.w800,
                      fontSize: 16))
            else if (b.progress != null)
              Text('Progress: ${b.progress}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final all = computeBadges(store.races);
          final earned = all.where((b) => b.earned).toList();
          final locked = all.where((b) => !b.earned).toList();
          final shown = [...earned, ...locked];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SoftCard(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      RingProgress(
                        value: all.isEmpty ? 0 : earned.length / all.length,
                        size: 92,
                        stroke: 11,
                        color: AppTheme.purpleMid,
                        child: Text('${earned.length}',
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${earned.length} of ${all.length} badges',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                              earned.isEmpty
                                  ? 'Finish a race to win your first badge.'
                                  : earned.length == all.length
                                      ? 'You have every badge. Legend!'
                                      : '${locked.length} more to chase.',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.66,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final b = shown[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _show(context, b),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: scheme.surface
                                .withValues(alpha: b.earned ? 1 : 0.6),
                          ),
                          child: Column(
                            children: [
                              Crest(badge: b.badge, earned: b.earned, size: 78),
                              const SizedBox(height: 4),
                              Text(
                                b.badge.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: b.earned ? null : Colors.grey,
                                ),
                              ),
                              if (!b.earned && b.progress != null)
                                Text(b.progress!,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: shown.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

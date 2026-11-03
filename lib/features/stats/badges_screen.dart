import 'package:flutter/material.dart';

import '../races/race_store.dart';
import 'badges.dart';

/// All badges: earned ones in colour, locked ones in grey with progress.
class BadgesScreen extends StatelessWidget {
  final RaceStore store;
  const BadgesScreen({super.key, required this.store});

  void _show(BuildContext context, BadgeResult b) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(b.badge.icon,
            size: 40, color: b.earned ? b.badge.color : Colors.grey),
        title: Text(b.badge.title),
        content: Text([
          b.badge.description,
          if (!b.earned && b.progress != null) 'Progress: ${b.progress}',
          if (b.earned) 'Earned!',
        ].join('\n\n')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final all = computeBadges(store.races);
          final earned = all.where((b) => b.earned).length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('$earned of ${all.length} earned',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: [
                    for (final b in all)
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _show(context, b),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: b.earned
                                    ? b.badge.color
                                    : Colors.grey.shade400,
                                width: b.earned ? 2 : 1),
                            color: b.earned
                                ? b.badge.color.withValues(alpha: 0.10)
                                : Colors.grey.withValues(alpha: 0.08),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(b.badge.icon,
                                  size: 34,
                                  color: b.earned
                                      ? b.badge.color
                                      : Colors.grey.shade400),
                              const SizedBox(height: 6),
                              Text(
                                b.badge.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
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
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

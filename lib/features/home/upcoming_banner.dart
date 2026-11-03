import 'package:flutter/material.dart';

import '../races/race.dart';

/// A reminder strip for the next planned race in the coming two months.
class UpcomingBanner extends StatefulWidget {
  final List<Race> races;
  const UpcomingBanner({super.key, required this.races});

  /// The nearest planned race from today to 60 days ahead, or null.
  static ({Race race, int days})? nextRace(List<Race> races, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    ({Race race, int days})? best;
    for (final r in races) {
      if (r.status != RaceStatus.planned) continue;
      final d = DateTime(r.date.year, r.date.month, r.date.day)
          .difference(today)
          .inDays;
      if (d < 0 || d > 60) continue;
      if (best == null || d < best.days) best = (race: r, days: d);
    }
    return best;
  }

  @override
  State<UpcomingBanner> createState() => _UpcomingBannerState();
}

class _UpcomingBannerState extends State<UpcomingBanner> {
  bool _hidden = false;

  String _when(int days) {
    if (days == 0) return 'is today!';
    if (days == 1) return 'is tomorrow';
    return 'is in $days days';
  }

  String _tip(int days) {
    if (days == 0) return 'Good luck out there!';
    if (days <= 2) return 'Rest up, hydrate and lay out your kit.';
    if (days <= 7) return 'Race week: keep it easy and sleep well.';
    if (days <= 21) return 'Taper time. Trust your training.';
    return 'Keep building.';
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final n = UpcomingBanner.nextRace(widget.races);
    if (n == null) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
        child: Row(
          children: [
            const Icon(Icons.alarm),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${n.race.name} ${_when(n.days)}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(_tip(n.days),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Hide',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _hidden = true),
            ),
          ],
        ),
      ),
    );
  }
}

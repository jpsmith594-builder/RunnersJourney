import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/tiles.dart';
import 'race.dart';
import 'race_store.dart';
import '../../core/units.dart';

/// The "Races" tab: a plain chronological list (newest first).
class RaceListView extends StatelessWidget {
  final RaceStore store;
  final void Function(Race race) onEdit;

  const RaceListView({super.key, required this.store, required this.onEdit});

  Future<void> _confirmDelete(BuildContext context, Race race) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete race?'),
        content: Text(race.name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await store.delete(race);
  }

  @override
  Widget build(BuildContext context) {
    if (store.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (store.error != null && store.races.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load races.\n${store.error}',
              textAlign: TextAlign.center),
        ),
      );
    }
    final races = store.races.reversed.toList();
    if (races.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Your journey starts here.\nAdd your first race with the button below.',
              textAlign: TextAlign.center),
        ),
      );
    }
    final sum = RaceSummary.from(store.races);
    final next = sum.nextPlanned;
    return RefreshIndicator(
      onRefresh: store.load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 146,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatTile(
                  icon: Icons.flag,
                  color: AppTheme.runGreen(Theme.of(context).brightness),
                  label: 'Races run',
                  value: '${sum.finished}',
                  note: sum.thisYear > 0 ? '${sum.thisYear} this year' : null,
                ),
                StatTile(
                  icon: Icons.directions_run,
                  color: AppTheme.purpleMid,
                  label: 'Distance',
                  value: formatNumber(toUnit(sum.km)),
                  unit: unitLabel(),
                  note: sum.kmThisYear > 0
                      ? '${formatDistance(sum.kmThisYear)} this year'
                      : null,
                ),
                StatTile(
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF00A86B),
                  label: 'Time racing',
                  value: sum.seconds >= 3600
                      ? (sum.seconds / 3600).toStringAsFixed(1)
                      : '${(sum.seconds / 60).round()}',
                  unit: sum.seconds >= 3600 ? 'h' : 'min',
                ),
                StatTile(
                  icon: Icons.event_available,
                  color: const Color(0xFFFF9F0A),
                  label: 'Next race',
                  value: next == null ? '-' : '${next.days}',
                  unit: next == null ? null : (next.days == 1 ? 'day' : 'days'),
                  note: next?.race.name,
                ),
              ],
            ),
          ),
          const SectionTitle('All races'),
          for (final r in races) _raceCard(context, r),
        ],
      ),
    );
  }

  Widget _raceCard(BuildContext context, Race r) {
    final done = r.status == RaceStatus.completed;
    final muted =
        Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7);
    final (icon, color) = switch (r.status) {
      RaceStatus.completed => (
          Icons.flag,
          AppTheme.runGreen(Theme.of(context).brightness)
        ),
      RaceStatus.planned => (Icons.flag_outlined, const Color(0xFFFF9F0A)),
      RaceStatus.dnf => (Icons.block, const Color(0xFFE5484D)),
      RaceStatus.dns => (Icons.remove_circle_outline, Colors.grey),
    };
    final chips = <(String, Color)>[
      if (r.distanceKm != null) (formatDistance(r.distanceKm!), color),
      if (done && r.finishTimeSeconds != null) (r.formattedTime, color),
      if (done && r.pace != null) (r.pace!, color),
      if (done && r.overallPosition != null) ('Pos ${r.overallPosition}', color),
      if (done && r.medal != null)
        (
          '${r.medal![0].toUpperCase()}${r.medal!.substring(1)} medal',
          medalColor(r.medal!)
        ),
    ];
    return SoftCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      onTap: () => onEdit(r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                    [
                      DateFormat.yMMMd().format(r.date),
                      if (r.locationName != null) r.locationName!,
                    ].join(' · '),
                    style: TextStyle(color: muted)),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final (text, c) in chips)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(text,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline, color: muted),
            onPressed: () => _confirmDelete(context, r),
          ),
        ],
      ),
    );
  }
}

/// Metal colour of a gold, silver or bronze medal.
Color medalColor(String medal) {
  switch (medal) {
    case 'gold':
      return const Color(0xFFFFB400);
    case 'silver':
      return const Color(0xFF9AA5B4);
    default:
      return const Color(0xFFCD7F32);
  }
}

/// Numbers for the tiles at the top of the Races tab.
class RaceSummary {
  final int finished;
  final int thisYear;
  final double km;
  final double kmThisYear;
  final int seconds;
  final ({Race race, int days})? nextPlanned;

  const RaceSummary({
    required this.finished,
    required this.thisYear,
    required this.km,
    required this.kmThisYear,
    required this.seconds,
    required this.nextPlanned,
  });

  factory RaceSummary.from(List<Race> races, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    var finished = 0, thisYear = 0, seconds = 0;
    var km = 0.0, kmYear = 0.0;
    ({Race race, int days})? next;
    for (final r in races) {
      if (r.status == RaceStatus.completed) {
        finished++;
        km += r.distanceKm ?? 0;
        seconds += r.finishTimeSeconds ?? 0;
        if (r.date.year == n.year) {
          thisYear++;
          kmYear += r.distanceKm ?? 0;
        }
      } else if (r.status == RaceStatus.planned) {
        final d = DateTime(r.date.year, r.date.month, r.date.day)
            .difference(today)
            .inDays;
        if (d >= 0 && (next == null || d < next.days)) {
          next = (race: r, days: d);
        }
      }
    }
    return RaceSummary(
      finished: finished,
      thisYear: thisYear,
      km: km,
      kmThisYear: kmYear,
      seconds: seconds,
      nextPlanned: next,
    );
  }
}

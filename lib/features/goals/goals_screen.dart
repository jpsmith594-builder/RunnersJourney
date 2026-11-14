import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/tiles.dart';
import '../profile/runner_stats.dart';
import '../races/race_store.dart';
import 'goal_store.dart';
import 'goals.dart';
import '../../core/units.dart';
import '../../core/errors.dart';

/// Yearly goals with progress rings, plus how close the next card category
/// and the next badge are.
class GoalsScreen extends StatelessWidget {
  final RaceStore races;
  final GoalStore goals;
  const GoalsScreen({super.key, required this.races, required this.goals});

  Future<void> _edit(BuildContext context) async {
    final km = TextEditingController(
        text: goals.goalKm == null
            ? ''
            : formatNumber(toUnit(goals.goalKm!.toDouble())));
    final rc = TextEditingController(text: goals.goalRaces?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('My ${DateTime.now().year} goals'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: km,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                  labelText: 'Distance goal (${unitLabel()})',
                  helperText: 'Leave empty for no distance goal'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rc,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Races goal',
                  helperText: 'Leave empty for no races goal'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    int? parse(String t, int max) {
      final v = int.tryParse(t.trim());
      return (v == null || v <= 0) ? null : (v > max ? max : v);
    }

    try {
      await goals.save(km: parse(km.text, 100000) == null
          ? null
          : fromUnit(parse(km.text, 100000)!.toDouble()).round(), races: parse(rc.text, 1000));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failMessage('Could not save goals', e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            tooltip: 'Set goals',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListenableBuilder(
        listenable: Listenable.merge([races, goals]),
        builder: (context, _) {
          final g = goalProgress(races.races, year,
              goalKm: goals.goalKm, goalRaces: goals.goalRaces);
          final stats = computeStats(races.races);
          final badge = nextBadge(races.races);
          final green = AppTheme.runGreen(Theme.of(context).brightness);
          final noGoals = g.goalKm == null && g.goalRaces == null;
          final now = DateTime.now();
          final prompt = needsNewYearPrompt(goals.byYear, now);
          final last = latestGoalBefore(goals.byYear, year);
          final past = goals.byYear.values
              .where((e) => e.year < year && !e.isEmpty)
              .toList()
            ..sort((a, b) => b.year.compareTo(a.year));

          Widget goalCard(String title, String value, String? hint,
              double? fraction, Color color) {
            return SoftCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  RingProgress(
                    value: fraction ?? 0,
                    color: color,
                    child: Text(
                        fraction == null ? '-' : '${(fraction * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w800)),
                        Text(value,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900)),
                        if (hint != null)
                          Text(hint,
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionTitle('$year goals'),
              if (prompt && last != null)
                SoftCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set your $year goals',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Last year you aimed for ${[
                        if (last.races != null) '${last.races} races',
                        if (last.km != null) formatDistance(last.km!.toDouble()),
                      ].join(' and ')}. Keep the same, or choose new ones.'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                              onPressed: () async {
                                try {
                                  await goals.saveFor(year,
                                      km: last.km, races: last.races);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                failMessage('Could not save goals', e))));
                                  }
                                }
                              },
                              child: const Text('Keep the same')),
                          OutlinedButton(
                              onPressed: () => _edit(context),
                              child: const Text('Choose new')),
                        ],
                      ),
                    ],
                  ),
                ),
              if (noGoals && !prompt)
                SoftCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Set a goal for the year',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text(
                          'Pick a distance and a number of races, and watch '
                          'the rings fill as you finish races.'),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: () => _edit(context),
                          child: const Text('Set my goals')),
                    ],
                  ),
                ),
              if (g.goalKm != null)
                goalCard(
                    'Distance',
                    '${formatNumber(toUnit(g.km))} / ${formatDistance(g.goalKm!.toDouble())}',
                    g.kmHint(DateTime.now()),
                    g.kmFraction,
                    green),
              if (g.goalRaces != null)
                goalCard('Races', '${g.races} / ${g.goalRaces}', g.racesHint(),
                    g.racesFraction, AppTheme.navyLight),
              if (past.isNotEmpty) ...[
                const SectionTitle('Past years'),
                SoftCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      for (final e in past)
                        Builder(builder: (context) {
                          final pg = goalProgress(races.races, e.year,
                              goalKm: e.km, goalRaces: e.races);
                          final done = yearAchieved(pg);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Text('${e.year}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(width: 14),
                                Expanded(child: Text(yearResult(pg))),
                                Icon(
                                    done
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    size: 20,
                                    color: done ? green : null),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
              const SectionTitle('Next up'),
              SoftCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: _CategoryProgress(stats: stats),
              ),
              if (badge != null)
                SoftCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      IconBubble(
                          icon: badge.badge.icon, color: badge.badge.color),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(badge.badge.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text(badge.badge.description,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text(badge.progress ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      ),
    );
  }
}

class _CategoryProgress extends StatelessWidget {
  final RunnerStats stats;
  const _CategoryProgress({required this.stats});

  String _name(CardTier t) => switch (t) {
        CardTier.club => 'Club runner',
        _ => '${t.name[0].toUpperCase()}${t.name.substring(1)}',
      };

  @override
  Widget build(BuildContext context) {
    final tier = stats.tier;
    final next = stats.pointsToNext;
    final isTop = next == null;
    final start = tierStarts[tier]!;
    final end = isTop
        ? 1000
        : tierStarts[CardTier.values[tier.index + 1]]!;
    final fraction = isTop ? 1.0 : (stats.rating - start) / (end - start);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Runner card: ${_name(tier)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            Text('${stats.rating}',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0).toDouble(), minHeight: 10),
        ),
        const SizedBox(height: 6),
        Text(
          isTop
              ? 'You have reached the top category.'
              : '$next points to ${_name(CardTier.values[tier.index + 1])}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

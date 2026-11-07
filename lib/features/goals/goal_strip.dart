import 'package:flutter/material.dart';

import '../../core/tiles.dart';
import '../races/race_store.dart';
import 'goal_store.dart';
import 'goals.dart';

/// A slim progress strip on the home screen, shown once a goal is set.
class GoalStrip extends StatelessWidget {
  final RaceStore races;
  final GoalStore goals;
  final VoidCallback onTap;
  const GoalStrip(
      {super.key, required this.races, required this.goals, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([races, goals]),
      builder: (context, _) {
        final now = DateTime.now();
        final year = now.year;
        if (goals.goalKm == null && goals.goalRaces == null) {
          // Early in a new year, offer to set (or keep) the goals.
          if (now.month <= 3 && needsNewYearPrompt(goals.byYear, now)) {
            return SoftCard(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: InkWell(
                onTap: onTap,
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Set your $year goals',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        final g = goalProgress(races.races, year,
            goalKm: goals.goalKm, goalRaces: goals.goalRaces);
        // The strip shows the races goal when there is one, else distance.
        final useKm = g.goalRaces == null;
        final fraction = (useKm ? g.kmFraction : g.racesFraction) ?? 0;
        final label = useKm
            ? '$year goal: ${g.km.toStringAsFixed(g.km >= 100 ? 0 : 1)} / ${g.goalKm} km'
            : '$year goal: ${g.races} / ${g.goalRaces} races';
        return SoftCard(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    Text('${(fraction * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: fraction, minHeight: 8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

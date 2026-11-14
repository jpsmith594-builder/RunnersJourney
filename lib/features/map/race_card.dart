import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../friends/reactions.dart';
import '../photos/photo_widgets.dart';
import '../races/race.dart';
import '../../core/units.dart';
import 'distance_colours.dart';

/// Small summary card shown when a race pin is tapped (or hovered on desktop).
class RaceCard extends StatelessWidget {
  final Race race;
  final VoidCallback onEdit;
  final VoidCallback onClose;

  const RaceCard({
    super.key,
    required this.race,
    required this.onEdit,
    required this.onClose,
  });

  String get _statusLabel {
    switch (race.status) {
      case RaceStatus.completed:
        return 'Completed';
      case RaceStatus.dnf:
        return 'Did not finish';
      case RaceStatus.dns:
        return 'Did not start';
      case RaceStatus.planned:
        return 'Planned';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final done = race.status == RaceStatus.completed;
    final stats = <String>[
      if (race.distanceKm != null) formatDistance(race.distanceKm!),
      if (done && race.finishTimeSeconds != null) race.formattedTime,
      if (done && race.pace != null) race.pace!,
      if (done && race.overallPosition != null)
        'Overall ${race.overallPosition}',
      if (done && race.ageGroupPosition != null)
        'Age group ${race.ageGroupPosition}',
    ];
    return Card(
      elevation: 6,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    race.name,
                    style:
                        t.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
            Text(
              [
                DateFormat.yMMMd().format(race.date),
                if (race.locationName != null) race.locationName!,
              ].join(' · '),
              style: t.bodySmall,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (distanceBand(race.distanceKm) case final b?) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: b.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(b.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(_statusLabel,
                    style:
                        t.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(stats.join(' · '), style: t.bodyMedium),
            ],
            if (race.id != null) RacePhotoStrip(raceId: race.id!),
            if (race.id != null)
              ReactionsBar(raceId: race.id!, canReact: false),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onEdit, child: const Text('Edit')),
            ),
          ],
        ),
      ),
    );
  }
}

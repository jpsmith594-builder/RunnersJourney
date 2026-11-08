import 'package:flutter/material.dart';

import '../../core/tiles.dart';
import '../photos/photo_repository.dart';
import '../photos/photo_widgets.dart';
import '../photos/race_photo.dart';
import '../races/race.dart';
import '../../core/units.dart';

/// A finished race from the same day in an earlier year.
typedef Memory = ({Race race, int yearsAgo});

/// Finished races that took place on today's date in earlier years, most
/// recent first. A 29 February race also shows on 28 February in years
/// without a leap day.
List<Memory> onThisDay(List<Race> races, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final leap = DateTime(n.year, 3, 0).day == 29;
  final out = <Memory>[];
  for (final r in races) {
    if (r.status != RaceStatus.completed) continue;
    final years = n.year - r.date.year;
    if (years <= 0) continue;
    final same = r.date.month == n.month && r.date.day == n.day;
    final leapDay = !leap &&
        n.month == 2 &&
        n.day == 28 &&
        r.date.month == 2 &&
        r.date.day == 29;
    if (same || leapDay) out.add((race: r, yearsAgo: years));
  }
  out.sort((a, b) => a.yearsAgo.compareTo(b.yearsAgo));
  return out;
}

/// "On this day": a memory from a past year, with its first photo.
class OnThisDayBanner extends StatefulWidget {
  final List<Race> races;
  const OnThisDayBanner({super.key, required this.races});

  @override
  State<OnThisDayBanner> createState() => _OnThisDayBannerState();
}

class _OnThisDayBannerState extends State<OnThisDayBanner> {
  bool _hidden = false;
  String? _loadedFor;
  List<RacePhoto> _photos = const [];

  void _loadPhotos(Race r) {
    if (r.id == null || _loadedFor == r.id) return;
    _loadedFor = r.id;
    PhotoRepository().list(r.id!).then((p) {
      if (mounted && _loadedFor == r.id) setState(() => _photos = p);
    }).catchError((_) {});
  }

  String _ago(int y) => y == 1 ? 'A year ago today' : '$y years ago today';

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final memories = onThisDay(widget.races);
    if (memories.isEmpty) return const SizedBox.shrink();
    final m = memories.first;
    _loadPhotos(m.race);
    final r = m.race;
    final bits = [
      if (r.distanceKm != null) formatDistance(r.distanceKm!),
      if (r.finishTimeSeconds != null) r.formattedTime,
      if ((r.locationName ?? '').isNotEmpty) r.locationName!,
    ];
    final thumb = _photos.isEmpty ? null : _photos.first;
    return SoftCard(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: InkWell(
        onTap: thumb == null
            ? null
            : () => openPhotoViewer(context, _photos, 0),
        child: Row(
          children: [
            if (thumb != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(thumb.url,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(Icons.auto_stories))),
              )
            else
              const IconBubble(
                  icon: Icons.auto_stories, color: Color(0xFF8E5CF7), size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_ago(m.yearsAgo).toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                  Text(r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (bits.isNotEmpty)
                    Text(
                        bits.join('  ·  ') +
                            (memories.length > 1
                                ? '  ·  +${memories.length - 1} more'
                                : ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

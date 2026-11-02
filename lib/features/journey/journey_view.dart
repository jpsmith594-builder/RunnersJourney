import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/season.dart';
import '../../core/season_theme.dart';
import '../races/race.dart';
import '../races/race_store.dart';
import 'trail_layout.dart';
import 'trail_painter.dart';

/// The "Journey" tab: races as points of interest along a jungle trail.
/// Hover (desktop/web) or tap / long-press (phone) a POI to see its race card.
class JourneyView extends StatefulWidget {
  final RaceStore store;
  final void Function(Race race) onEdit;

  const JourneyView({super.key, required this.store, required this.onEdit});

  @override
  State<JourneyView> createState() => _JourneyViewState();
}

class _JourneyViewState extends State<JourneyView> {
  final _scroll = ScrollController();
  String? _selectedId;
  bool _jumped = false;

  static const double _cardWidth = 230;
  static const double _cardHeightEstimate = 170;
  static const double _poiBoxWidth = 110;
  static const double _poiBoxHeight = 74;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(String? id) {
    if (_selectedId != id) setState(() => _selectedId = id);
  }

  /// Start the view near the runner's latest passed race.
  void _jumpToLatest(TrailLayout layout, double viewportH) {
    if (_jumped || layout.points.isEmpty) return;
    _jumped = true;
    final idx = layout.points.lastIndexWhere((p) => p.passed);
    if (idx < 0) return;
    final fromBottom = layout.height - layout.points[idx].pos.dy;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = (fromBottom - viewportH * 0.4)
          .clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        if (store.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (store.error != null && store.races.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load your journey.\n${store.error}',
                  textAlign: TextAlign.center),
            ),
          );
        }

        final season =
            seasonFor(DateTime.now(), southern: store.southern);
        final theme = themeFor(season);

        return LayoutBuilder(builder: (context, c) {
          final layout = layoutTrail(store.races, c.maxWidth, c.maxHeight);
          _jumpToLatest(layout, c.maxHeight);

          TrailPoint? selected;
          for (final p in layout.points) {
            if (p.race.id == _selectedId) selected = p;
          }

          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scroll,
                reverse: true, // starts at the bottom: the beginning of the journey
                child: SizedBox(
                  width: layout.width,
                  height: layout.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _select(null),
                          child: CustomPaint(
                            painter: TrailPainter(theme, layout),
                          ),
                        ),
                      ),
                      if (store.races.isEmpty)
                        Positioned(
                          left: 32,
                          right: 32,
                          bottom: 110,
                          child: _EmptyHint(),
                        ),
                      for (final p in layout.points)
                        Positioned(
                          left: p.pos.dx - _poiBoxWidth / 2,
                          top: p.pos.dy - 22,
                          width: _poiBoxWidth,
                          height: _poiBoxHeight,
                          child: _Poi(
                            point: p,
                            selected: p.race.id == _selectedId,
                            onHover: () => _select(p.race.id),
                            onTap: () => _select(
                                p.race.id == _selectedId ? null : p.race.id),
                          ),
                        ),
                      if (selected != null) _positionedCard(selected, layout),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Chip(
                  avatar: Icon(theme.icon, size: 18),
                  label: Text(theme.label),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _positionedCard(TrailPoint p, TrailLayout layout) {
    final left = (p.pos.dx - _cardWidth / 2)
        .clamp(8.0, layout.width - _cardWidth - 8.0);
    // Prefer showing the card above the POI; fall back to below near the top.
    final above = p.pos.dy - 22 - _cardHeightEstimate - 6;
    final top = above >= 0 ? above : p.pos.dy - 22 + _poiBoxHeight + 6;
    return Positioned(
      left: left,
      top: top,
      width: _cardWidth,
      child: _RaceCard(
        race: p.race,
        onEdit: () => widget.onEdit(p.race),
        onClose: () => _select(null),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Your trail starts here.\nTap "Add race" to place your first point of interest.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _Poi extends StatelessWidget {
  final TrailPoint point;
  final bool selected;
  final VoidCallback onHover;
  final VoidCallback onTap;

  const _Poi({
    required this.point,
    required this.selected,
    required this.onHover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = point.race.status;
    final Color fill;
    final IconData icon;
    switch (status) {
      case RaceStatus.completed:
        fill = const Color(0xFFF2B01E);
        icon = Icons.emoji_events;
      case RaceStatus.dnf:
        fill = const Color(0xFFE67E22);
        icon = Icons.warning_amber_rounded;
      case RaceStatus.dns:
        fill = const Color(0xFF9E9E9E);
        icon = Icons.block;
      case RaceStatus.planned:
        fill = Colors.white;
        icon = Icons.flag;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onTap,
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: fill,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))
                  ],
                ),
                child: Icon(icon,
                    size: 22,
                    color: status == RaceStatus.planned
                        ? const Color(0xFF2E7D32)
                        : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                point.race.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RaceCard extends StatelessWidget {
  final Race race;
  final VoidCallback onEdit;
  final VoidCallback onClose;

  const _RaceCard(
      {required this.race, required this.onEdit, required this.onClose});

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
      if (race.distanceKm != null) '${race.distanceKm} km',
      if (done && race.finishTimeSeconds != null) race.formattedTime,
      if (done && race.overallPosition != null)
        'Overall ${race.overallPosition}',
      if (done && race.ageGroupPosition != null)
        'Age group ${race.ageGroupPosition}',
    ];
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(race.name,
                      style: t.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
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
            Text(_statusLabel,
                style: t.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(stats.join(' · '), style: t.bodyMedium),
            ],
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

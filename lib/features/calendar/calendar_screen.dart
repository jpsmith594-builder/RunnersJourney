import 'package:flutter/material.dart';

import '../../core/tiles.dart';
import 'race_event.dart';

/// Browse well-known South African races and add them to the plan or the
/// bucket list in one tap.
class CalendarScreen extends StatefulWidget {
  final void Function(RaceEvent event) onPlan;
  final void Function(RaceEvent event) onBucket;

  /// Opens a blank race form for a race that is not in the list.
  final VoidCallback onAddOwn;

  const CalendarScreen({
    super.key,
    required this.onPlan,
    required this.onBucket,
    required this.onAddOwn,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _query = '';

  Widget _notListed() => SoftCard(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: widget.onAddOwn,
        child: const Row(
          children: [
            IconBubble(
                icon: Icons.add_location_alt_outlined,
                color: Color(0xFF6B1B9A),
                size: 38),
            SizedBox(width: 12),
            Expanded(
              child: Text('Add a race that is not listed',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            Icon(Icons.chevron_right),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final events = kRaceEvents
        .where((e) =>
            q.isEmpty ||
            e.name.toLowerCase().contains(q) ||
            (e.town ?? '').toLowerCase().contains(q) ||
            e.when.toLowerCase().contains(q))
        .toList();
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('South African races')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by race, town or month',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Well-known South African races with their usual timing. More countries are '
              'coming soon. Dates change every year, so check the official site.',
              style: t.bodySmall,
            ),
          ),
          _notListed(),
          Expanded(
            child: events.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                          'No races match your search. Use "Add a race that is not listed" above to add it yourself.',
                          textAlign: TextAlign.center),
                    ),
                  )
                : ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = events[i];
                      return ListTile(
                        title: Text(e.name),
                        subtitle: Text([
                          if (e.town != null) e.town!,
                          e.distanceLabel,
                          e.when,
                          if (e.note != null) e.note!,
                        ].join('  ·  ')),
                        isThreeLine: e.note != null,
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Add',
                          icon: const Icon(Icons.add_circle_outline),
                          onSelected: (v) =>
                              v == 'plan' ? widget.onPlan(e) : widget.onBucket(e),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'plan', child: Text('Plan this race')),
                            PopupMenuItem(
                                value: 'bucket',
                                child: Text('Add to bucket list')),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

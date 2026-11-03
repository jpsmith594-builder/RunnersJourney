import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'race.dart';
import 'race_store.dart';

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
    return RefreshIndicator(
      onRefresh: store.load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: races.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = races[i];
          final done = r.status == RaceStatus.completed;
          final details = [
            if (r.distanceKm != null) '${r.distanceKm} km',
            if (done && r.finishTimeSeconds != null) r.formattedTime,
            if (done && r.pace != null) r.pace!,
            if (done && r.overallPosition != null) 'Pos ${r.overallPosition}',
          ].join(' · ');
          return ListTile(
            leading: Icon(
              done ? Icons.flag : Icons.flag_outlined,
              color: done ? Colors.green : null,
            ),
            title: Text(r.name),
            subtitle: Text([
              DateFormat.yMMMd().format(r.date),
              if (details.isNotEmpty) details,
            ].join('\n')),
            isThreeLine: details.isNotEmpty,
            onTap: () => onEdit(r),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, r),
            ),
          );
        },
      ),
    );
  }
}

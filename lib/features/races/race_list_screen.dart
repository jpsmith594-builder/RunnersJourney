import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'race.dart';
import 'race_form_screen.dart';
import 'race_repository.dart';

/// Temporary list view of races. The jungle trail replaces this in the next step.
class RaceListScreen extends StatefulWidget {
  const RaceListScreen({super.key});

  @override
  State<RaceListScreen> createState() => _RaceListScreenState();
}

class _RaceListScreenState extends State<RaceListScreen> {
  final _repo = RaceRepository();
  late Future<List<Race>> _future = _repo.list();

  void _reload() => setState(() => _future = _repo.list());

  Future<void> _openForm([Race? race]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RaceFormScreen(race: race)),
    );
    if (changed == true) _reload();
  }

  Future<void> _delete(Race race) async {
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
    if (ok == true) {
      await _repo.delete(race.id!);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Journey'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add race'),
      ),
      body: FutureBuilder<List<Race>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load races.\n${snap.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          final races = snap.data!;
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
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: races.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = races[i];
              final done = r.status == RaceStatus.completed;
              final details = [
                if (r.distanceKm != null) '${r.distanceKm} km',
                if (done && r.finishTimeSeconds != null) r.formattedTime,
                if (done && r.overallPosition != null)
                  'Pos ${r.overallPosition}',
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
                onTap: () => _openForm(r),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(r),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

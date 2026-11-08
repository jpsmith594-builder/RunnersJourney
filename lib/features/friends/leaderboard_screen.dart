import 'package:flutter/material.dart';

import '../races/race.dart';
import 'friend_entry.dart';
import 'friends_repository.dart';
import '../../core/units.dart';

enum _Metric { km, races, towns }

class _Row {
  final String name;
  final bool me;
  final List<Race> races; // completed only
  const _Row(this.name, this.me, this.races);

  double get km => races.fold(0.0, (s, r) => s + (r.distanceKm ?? 0));
  int get count => races.length;
  int get towns => {
        for (final r in races)
          if ((r.locationName ?? '').trim().isNotEmpty)
            r.locationName!.trim().toLowerCase()
      }.length;

  num value(_Metric m) {
    switch (m) {
      case _Metric.km:
        return km;
      case _Metric.races:
        return count;
      case _Metric.towns:
        return towns;
    }
  }
}

/// You and your friends ranked by kilometres, races or towns, this year or
/// all time.
class LeaderboardScreen extends StatefulWidget {
  final List<FriendEntry> friends;
  final String myName;
  final List<Race> myRaces;
  const LeaderboardScreen({
    super.key,
    required this.friends,
    required this.myName,
    required this.myRaces,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _repo = FriendsRepository();
  late final Future<List<_Row>> _rows = _load();
  _Metric _metric = _Metric.km;
  bool _thisYear = true;

  Future<List<_Row>> _load() async {
    List<Race> done(List<Race> l) =>
        l.where((r) => r.status == RaceStatus.completed).toList();
    final rows = <_Row>[
      _Row(widget.myName.trim().isEmpty ? 'You' : widget.myName.trim(), true,
          done(widget.myRaces)),
    ];
    final others = await Future.wait(widget.friends.map((f) async {
      try {
        return _Row(f.name, false, done(await _repo.racesOf(f.otherId)));
      } catch (_) {
        return _Row(f.name, false, const []);
      }
    }));
    rows.addAll(others);
    return rows;
  }

  _Row _filtered(_Row r) {
    if (!_thisYear) return r;
    final y = DateTime.now().year;
    return _Row(r.name, r.me, r.races.where((x) => x.date.year == y).toList());
  }

  String _format(_Row r) {
    switch (_metric) {
      case _Metric.km:
        return formatDistance(r.km);
      case _Metric.races:
        return '${r.count} race${r.count == 1 ? '' : 's'}';
      case _Metric.towns:
        return '${r.towns} town${r.towns == 1 ? '' : 's'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: FutureBuilder<List<_Row>>(
        future: _rows,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = (snap.data ?? const <_Row>[]).map(_filtered).toList()
            ..sort((a, b) => b.value(_metric).compareTo(a.value(_metric)));
          const medals = ['\u{1F947}', '\u{1F948}', '\u{1F949}'];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<_Metric>(
                        segments: const [
                          ButtonSegment(value: _Metric.km, label: Text('Km')),
                          ButtonSegment(
                              value: _Metric.races, label: Text('Races')),
                          ButtonSegment(
                              value: _Metric.towns, label: Text('Towns')),
                        ],
                        selected: {_metric},
                        onSelectionChanged: (s) =>
                            setState(() => _metric = s.first),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                        value: true,
                        label: Text('${DateTime.now().year}')),
                    const ButtonSegment(value: false, label: Text('All time')),
                  ],
                  selected: {_thisYear},
                  onSelectionChanged: (s) =>
                      setState(() => _thisYear = s.first),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    return ListTile(
                      tileColor: r.me
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.4)
                          : null,
                      leading: SizedBox(
                        width: 36,
                        child: Center(
                          child: Text(
                            i < 3 ? medals[i] : '${i + 1}',
                            style: TextStyle(fontSize: i < 3 ? 24 : 16),
                          ),
                        ),
                      ),
                      title: Text(r.me ? '${r.name} (you)' : r.name),
                      trailing: Text(_format(r),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    );
                  },
                ),
              ),
              if (widget.friends.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Add friends to see how you compare.'),
                ),
            ],
          );
        },
      ),
    );
  }
}

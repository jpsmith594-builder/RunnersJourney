import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reaction kinds: database key and the emoji shown.
const Map<String, String> kReactions = {
  'clap': '\u{1F44F}',
  'fire': '\u{1F525}',
  'muscle': '\u{1F4AA}',
  'party': '\u{1F389}',
};

class ReactionCounts {
  final Map<String, int> counts;
  final Set<String> mine;
  const ReactionCounts(this.counts, this.mine);
}

class ReactionsRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<ReactionCounts> load(String raceId) async {
    final uid = _db.auth.currentUser!.id;
    final rows =
        await _db.from('race_reactions').select().eq('race_id', raceId);
    final counts = <String, int>{};
    final mine = <String>{};
    for (final r in rows as List) {
      final m = r as Map<String, dynamic>;
      final e = m['emoji'] as String;
      counts[e] = (counts[e] ?? 0) + 1;
      if (m['user_id'] == uid) mine.add(e);
    }
    return ReactionCounts(counts, mine);
  }

  Future<void> set(String raceId, String emoji, bool on) async {
    final uid = _db.auth.currentUser!.id;
    if (on) {
      await _db
          .from('race_reactions')
          .insert({'race_id': raceId, 'user_id': uid, 'emoji': emoji});
    } else {
      await _db
          .from('race_reactions')
          .delete()
          .eq('race_id', raceId)
          .eq('user_id', uid)
          .eq('emoji', emoji);
    }
  }
}

/// A row of reaction chips for one race. With [canReact] a friend can tap to
/// cheer; without it (your own race) only reactions already received show.
class ReactionsBar extends StatefulWidget {
  final String raceId;
  final bool canReact;
  const ReactionsBar({super.key, required this.raceId, required this.canReact});

  @override
  State<ReactionsBar> createState() => _ReactionsBarState();
}

class _ReactionsBarState extends State<ReactionsBar> {
  final _repo = ReactionsRepository();
  Map<String, int> _counts = {};
  Set<String> _mine = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _repo.load(widget.raceId);
      if (mounted) {
        setState(() {
          _counts = {...r.counts};
          _mine = {...r.mine};
          _loaded = true;
        });
      }
    } catch (_) {
      // Reactions are optional (the table may not exist yet).
    }
  }

  Future<void> _toggle(String key) async {
    final on = !_mine.contains(key);
    setState(() {
      if (on) {
        _mine.add(key);
        _counts[key] = (_counts[key] ?? 0) + 1;
      } else {
        _mine.remove(key);
        _counts[key] = ((_counts[key] ?? 1) - 1).clamp(0, 9999);
      }
    });
    try {
      await _repo.set(widget.raceId, key, on);
    } catch (_) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final keys = [
      for (final k in kReactions.keys)
        if (widget.canReact || (_counts[k] ?? 0) > 0) k
    ];
    if (keys.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        children: [
          for (final k in keys)
            ChoiceChip(
              visualDensity: VisualDensity.compact,
              label: Text(
                  '${kReactions[k]}${(_counts[k] ?? 0) > 0 ? ' ${_counts[k]}' : ''}'),
              selected: _mine.contains(k),
              onSelected: widget.canReact ? (_) => _toggle(k) : null,
            ),
        ],
      ),
    );
  }
}

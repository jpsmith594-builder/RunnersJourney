import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../friends/friend_entry.dart';
import '../map/distance_colours.dart';
import '../races/race.dart';
import '../races/race_store.dart';
import 'medal.dart';
import 'medal_edit_screen.dart';
import 'medal_photo_flow.dart';
import 'medal_repository.dart';
import 'medal_widgets.dart';

/// "My Medals": photographed medals hung from titanium bars on a purple wall.
class MedalWallScreen extends StatefulWidget {
  /// The signed-in runner's own races (own wall only).
  final RaceStore? store;

  /// Set when looking at a friend's wall: read-only.
  final FriendEntry? friend;
  final List<Race> friendRaces;

  const MedalWallScreen({super.key, required RaceStore this.store})
      : friend = null,
        friendRaces = const [];

  const MedalWallScreen.friend({
    super.key,
    required FriendEntry this.friend,
    required this.friendRaces,
  }) : store = null;

  @override
  State<MedalWallScreen> createState() => _MedalWallScreenState();
}

class _MedalWallScreenState extends State<MedalWallScreen> {
  static const _perRow = 3;
  final _repo = MedalRepository();
  List<Medal> _medals = const [];
  bool _shared = true;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.friend == null) {
      _repo.sharedWithFriends().then((v) {
        if (mounted) setState(() => _shared = v);
      }).catchError((_) {});
    }
  }

  Future<void> _setShared(bool v) async {
    setState(() => _shared = v);
    try {
      await _repo.setSharedWithFriends(v);
    } catch (_) {
      if (!mounted) return;
      setState(() => _shared = !v);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not change that. Check your connection.')));
    }
  }

  Future<void> _load({bool refresh = false}) async {
    try {
      final f = widget.friend;
      final medals = f == null
          ? await _repo.list(refresh: refresh)
          : await _repo.listOf(f.otherId);
      if (!mounted) return;
      setState(() {
        _medals = _byDate(medals);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your medals. Check your connection and try again.';
      });
    }
  }

  /// Oldest first, by race date; medals with no race use the day they were added.
  List<Medal> _byDate(List<Medal> medals) {
    DateTime when(Medal m) => _raceOf(m)?.date ?? m.createdAt;
    return [...medals]..sort((a, b) => when(a).compareTo(when(b)));
  }

  Race? _raceOf(Medal m) {
    if (m.raceId == null) return null;
    for (final r in widget.store?.races ?? widget.friendRaces) {
      if (r.id == m.raceId) return r;
    }
    return null;
  }

  Future<void> _add() async {
    final cut = await pickAndAdjustMedalPhoto(context);
    if (cut == null || !mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => MedalEditScreen(store: widget.store!, bytes: cut)),
    );
    if (saved == true) await _load(refresh: true);
  }

  Future<void> _open(Medal m) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => MedalEditScreen(store: widget.store!, medal: m)),
    );
    if (changed == true) await _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final rowCount = _medals.isEmpty
        ? 1
        : (_medals.length / _perRow).ceil() +
            (_medals.length % _perRow == 0 ? 1 : 0);
    return Scaffold(
      backgroundColor: wallTop,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: widget.friend != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add medal'),
            ),
      body: Container(
        decoration: wallGradient,
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _load(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
              children: [
                LedTitle(widget.friend == null
                    ? 'My Medals'
                    : "${widget.friend!.name.split(' ').first}'s Medals"),
                const SizedBox(height: 10),
                Text(
                  _loading
                      ? 'Loading medals...'
                      : _medals.length == 1
                          ? '1 medal'
                          : '${_medals.length} medals',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFBBA8E2)),
                ),
                if (widget.friend == null)
                  SwitchListTile(
                    value: _shared,
                    onChanged: _setShared,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    dense: true,
                    activeTrackColor: const Color(0xFF2FD8FF),
                    title: const Text('Friends can see my wall',
                        style: TextStyle(color: Color(0xFFD9CCF2))),
                  ),
                const SizedBox(height: 28),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white)),
                        TextButton(
                            onPressed: () {
                              setState(() => _loading = true);
                              _load(refresh: true);
                            },
                            child: const Text('Try again')),
                      ],
                    ),
                  ),
                for (var row = 0; row < rowCount; row++) _buildRow(row),
                if (!_loading && _error == null && _medals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.friend == null
                          ? 'Photograph a medal on a plain surface and hang it here.'
                          : 'No medals to show. They may not have hung any yet, or keep their wall private.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFA592CF)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(int row) {
    final start = row * _perRow;
    final slots = <Widget>[];
    for (var i = 0; i < _perRow; i++) {
      final index = start + i;
      slots.add(Expanded(
        child: index < _medals.length
            ? _slot(_medals[index])
            : const SizedBox.shrink(),
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Stack(
        children: [
          const Positioned(left: 0, right: 0, top: 0, child: HangerBar()),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: slots,
            ),
          ),
          // Keeps empty bars the height of a bar with medals on it.
          const SizedBox(height: 194, width: double.infinity),
        ],
      ),
    );
  }

  Widget _slot(Medal m) {
    final race = _raceOf(m);
    final title = race?.name ?? 'Medal';
    final date = race == null ? '' : DateFormat('MMM yyyy').format(race.date);
    return Semantics(
      button: true,
      label: 'Medal, $title $date',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.friend != null ? null : () => _open(m),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, box) => Center(
                  child: MedalView(
                    image: NetworkImage(m.url),
                    metal: m.metal,
                    ribbon: m.ribbon,
                    ribbonColour: distanceColour(race?.distanceKm),
                    size: box.maxWidth < 92 ? box.maxWidth : 92,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFF3ECFF),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600),
              ),
              if (date.isNotEmpty)
                Text(date,
                    style: const TextStyle(
                        color: Color(0xFFA592CF), fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/tiles.dart';
import '../map/distance_colours.dart';
import '../races/race.dart';
import '../races/race_store.dart';
import '../subscription/limits.dart';
import 'medal.dart';
import 'medal_photo_flow.dart';
import 'medal_repository.dart';
import 'medal_widgets.dart';

/// Adds a new medal (give [bytes]) or edits one already on the wall (give
/// [medal]). Pops with true when something changed.
class MedalEditScreen extends StatefulWidget {
  final RaceStore store;
  final Medal? medal;
  final Uint8List? bytes;

  const MedalEditScreen({
    super.key,
    required this.store,
    this.medal,
    this.bytes,
  }) : assert((medal == null) != (bytes == null));

  @override
  State<MedalEditScreen> createState() => _MedalEditScreenState();
}

class _MedalEditScreenState extends State<MedalEditScreen> {
  final _repo = MedalRepository();
  late String? _raceId = widget.medal?.raceId;
  late MedalMetal _metal = widget.medal?.metal ?? MedalMetal.gold;
  late MedalRibbon _ribbon = widget.medal?.ribbon ?? MedalRibbon.blue;
  late Uint8List? _newBytes = widget.bytes;
  bool _busy = false;

  bool get _isNew => widget.medal == null;

  List<Race> get _races {
    final list = widget.store.races
        .where((r) => r.status == RaceStatus.completed && r.id != null)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  ImageProvider get _image {
    final bytes = _newBytes;
    if (bytes != null) return MemoryImage(bytes);
    return NetworkImage(widget.medal!.url);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// The colour of the linked race's distance group, if it has a distance.
  DistanceBand? get _raceBand {
    for (final r in widget.store.races) {
      if (r.id == _raceId) return distanceBand(r.distanceKm);
    }
    return null;
  }

  void _pickRace(String? id) {
    setState(() {
      _raceId = id;
      if (id != null) {
        for (final r in widget.store.races) {
          if (r.id == id) {
            final m = metalForRaceMedal(r.medal);
            if (m != null) _metal = m;
          }
        }
      }
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      if (_isNew) {
        await _repo.add(_newBytes!,
            raceId: _raceId, metal: _metal, ribbon: _ribbon);
      } else {
        await _repo.update(widget.medal!,
            raceId: _raceId,
            metal: _metal,
            ribbon: _ribbon,
            png: _newBytes);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (!handleLimitError(context, e)) {
        _toast('Could not save the medal. Check your connection and try again.');
      }
    }
  }

  Future<void> _changePhoto() async {
    final cut = await pickAndAdjustMedalPhoto(context);
    if (cut == null || !mounted) return;
    setState(() => _newBytes = cut);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this medal?'),
        content: const Text(
            'The medal comes off your wall. Your race stays as it is.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep it')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _repo.delete(widget.medal!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('Could not remove the medal. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final races = _races;
    final raceValue = races.any((r) => r.id == _raceId) ? _raceId : null;
    final fmt = DateFormat('d MMM yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New medal' : 'Medal'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Remove medal',
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: wallGradient.copyWith(
                borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 220, height: 12, child: HangerBar()),
                MedalView(
                    image: _image,
                    metal: _metal,
                    ribbon: _ribbon,
                    ribbonColour: _raceBand?.color,
                    size: 150),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _changePhoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(_isNew ? 'Retake or choose another photo' : 'Change photo'),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: raceValue,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Race (optional)',
                    helperText: 'Link the medal to a finished race',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('No race')),
                    for (final r in races)
                      DropdownMenuItem<String?>(
                        value: r.id,
                        child: Text('${r.name} · ${fmt.format(r.date)}',
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: _busy ? null : _pickRace,
                ),
                const SizedBox(height: 20),
                Text('Metal', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in MedalMetal.values)
                      ChoiceChip(
                        label: Text(m.label),
                        selected: _metal == m,
                        onSelected: _busy ? null : (_) => setState(() => _metal = m),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Ribbon', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_raceBand != null)
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                            color: _raceBand!.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The ribbon uses the ${_raceBand!.label} colour, '
                          'the same as on the map.',
                        ),
                      ),
                    ],
                  )
                else
                  Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final r in MedalRibbon.values)
                      Semantics(
                        label: '${r.label} ribbon',
                        selected: _ribbon == r,
                        button: true,
                        child: GestureDetector(
                          onTap: _busy ? null : () => setState(() => _ribbon = r),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: r.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _ribbon == r
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: Center(
                                child: Container(
                                    width: 6, height: 22, color: r.stripe)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isNew ? 'Hang on the wall' : 'Save'),
          ),
        ],
      ),
    );
  }
}

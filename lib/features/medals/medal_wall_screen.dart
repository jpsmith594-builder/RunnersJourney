import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../races/race.dart';
import '../races/race_store.dart';
import 'adjust_medal_screen.dart';
import 'medal.dart';
import 'medal_edit_screen.dart';
import 'medal_repository.dart';
import 'medal_widgets.dart';

/// "My Medals": photographed medals hung from titanium bars on a purple wall.
class MedalWallScreen extends StatefulWidget {
  final RaceStore store;
  const MedalWallScreen({super.key, required this.store});

  @override
  State<MedalWallScreen> createState() => _MedalWallScreenState();
}

class _MedalWallScreenState extends State<MedalWallScreen> {
  static const _perRow = 3;
  final _repo = MedalRepository();
  final _picker = ImagePicker();
  List<Medal> _medals = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    try {
      final medals = await _repo.list(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _medals = medals;
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

  Race? _raceOf(Medal m) {
    if (m.raceId == null) return null;
    for (final r in widget.store.races) {
      if (r.id == m.raceId) return r;
    }
    return null;
  }

  Future<void> _add() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              subtitle: const Text('Use a plain surface and good light'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    Uint8List bytes;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (file == null) return;
      bytes = await file.readAsBytes();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the camera or gallery.')));
      return;
    }
    if (!mounted) return;
    final cut = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => AdjustMedalScreen(bytes: bytes)),
    );
    if (cut == null || !mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => MedalEditScreen(store: widget.store, bytes: cut)),
    );
    if (saved == true) await _load(refresh: true);
  }

  Future<void> _open(Medal m) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => MedalEditScreen(store: widget.store, medal: m)),
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
      floatingActionButton: FloatingActionButton.extended(
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
                const LedTitle('My Medals'),
                const SizedBox(height: 10),
                Text(
                  _loading
                      ? 'Loading your medals...'
                      : _medals.length == 1
                          ? '1 medal'
                          : '${_medals.length} medals',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFBBA8E2)),
                ),
                const SizedBox(height: 36),
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
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Photograph a medal on a plain surface and hang it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFA592CF)),
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
        onTap: () => _open(m),
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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_repository.dart';
import 'race_photo.dart';

/// Full-screen, swipeable, zoomable photo viewer.
class PhotoViewerScreen extends StatelessWidget {
  final List<RacePhoto> photos;
  final int initial;
  const PhotoViewerScreen({super.key, required this.photos, this.initial = 0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Photos'),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: photos.length,
        itemBuilder: (context, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: Image.network(
              photos[i].url,
              fit: BoxFit.contain,
              loadingBuilder: (c, child, p) => p == null
                  ? child
                  : const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}

void openPhotoViewer(BuildContext context, List<RacePhoto> photos, int index) {
  Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PhotoViewerScreen(photos: photos, initial: index)));
}

/// A small row of thumbnails, used on the map's race card. Shows nothing when
/// the race has no photos.
class RacePhotoStrip extends StatefulWidget {
  final String raceId;
  const RacePhotoStrip({super.key, required this.raceId});

  @override
  State<RacePhotoStrip> createState() => _RacePhotoStripState();
}

class _RacePhotoStripState extends State<RacePhotoStrip> {
  late final Future<List<RacePhoto>> _photos =
      PhotoRepository().list(widget.raceId).catchError((_) => <RacePhoto>[]);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RacePhoto>>(
      future: _photos,
      builder: (context, snap) {
        final photos = snap.data ?? const <RacePhoto>[];
        if (photos.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8, right: 6),
          child: SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => openPhotoViewer(context, photos, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(photos[i].url,
                      width: 56, height: 56, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.broken_image))),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The photos section of the race form. For a race that already exists,
/// photos upload straight away; for a new race they are collected in
/// [pending] and uploaded by the form once the race is saved.
class PhotosEditor extends StatefulWidget {
  final String? raceId;
  final List<XFile> pending;
  final VoidCallback onPendingChanged;

  const PhotosEditor({
    super.key,
    required this.raceId,
    required this.pending,
    required this.onPendingChanged,
  });

  @override
  State<PhotosEditor> createState() => _PhotosEditorState();
}

class _PhotosEditorState extends State<PhotosEditor> {
  final _repo = PhotoRepository();
  final _picker = ImagePicker();
  List<RacePhoto> _saved = [];
  bool _loading = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final id = widget.raceId;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final list = await _repo.list(id, refresh: true);
      if (mounted) setState(() => _saved = list);
    } catch (e) {
      _toast('Could not load photos: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _add() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      // Downsized on pick, so photos stay around a few hundred KB.
      final file = await _picker.pickImage(
          source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
      if (file == null) return;
      final id = widget.raceId;
      if (id == null) {
        widget.pending.add(file);
        widget.onPendingChanged();
        setState(() {});
      } else {
        setState(() => _busy = true);
        await _repo.add(id, file);
        await _reload();
      }
    } catch (e) {
      _toast('Could not add photo: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _deleteSaved(RacePhoto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this photo?'),
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
    if (ok != true) return;
    try {
      await _repo.delete(p);
      await _reload();
    } catch (e) {
      _toast('Could not delete photo: $e');
    }
  }

  Widget _tile(Widget image, VoidCallback onTap, VoidCallback onRemove) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 90, height: 90, child: image),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 11,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final count = _saved.length + widget.pending.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Photos${count > 0 ? ' ($count)' : ''}',
                style: t.labelLarge),
            const Spacer(),
            TextButton.icon(
              onPressed: _busy ? null : _add,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add photo'),
            ),
          ],
        ),
        if (_loading && _saved.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          )
        else if (count == 0)
          Text('Add pictures from the race, the finish line or the day.',
              style: t.bodySmall)
        else
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _saved.length; i++) ...[
                  _tile(
                    Image.network(_saved[i].url, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image)),
                    () => openPhotoViewer(context, _saved, i),
                    () => _deleteSaved(_saved[i]),
                  ),
                  const SizedBox(width: 8),
                ],
                for (final f in widget.pending) ...[
                  _tile(
                    FutureBuilder<Uint8List>(
                      future: f.readAsBytes(),
                      builder: (c, s) => s.hasData
                          ? Image.memory(s.data!, fit: BoxFit.cover)
                          : const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    () {},
                    () {
                      widget.pending.remove(f);
                      widget.onPendingChanged();
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        if (widget.raceId == null && widget.pending.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('These upload when you save the race.',
                style: t.bodySmall),
          ),
      ],
    );
  }
}

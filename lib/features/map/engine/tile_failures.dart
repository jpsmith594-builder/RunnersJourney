import '../../../core/errors.dart';

/// Notices when map tiles keep failing to download and reports it once, so a
/// blank map can be diagnosed instead of guessed at. It never sends where the
/// runner was looking (no tile numbers or coordinates), and the map key is
/// removed from any error text.
class TileFailureReporter {
  final int threshold;
  final Duration window;
  final Duration cooldown;
  final DateTime Function() _now;
  final void Function(String template, List<Object> params) _send;

  final List<DateTime> _recent = [];
  DateTime? _lastSent;

  TileFailureReporter({
    required void Function(String template, List<Object> params) send,
    this.threshold = 5,
    this.window = const Duration(minutes: 1),
    this.cooldown = const Duration(minutes: 10),
    DateTime Function()? now,
  })  : _send = send,
        _now = now ?? DateTime.now;

  /// Call for every tile that fails. [zoom] is the tile's zoom level.
  void record(int zoom, Object error) {
    final now = _now();
    _recent
      ..add(now)
      ..removeWhere((t) => now.difference(t) > window);
    if (_recent.length < threshold) return;
    final last = _lastSent;
    if (last != null && now.difference(last) < cooldown) return;
    _lastSent = now;
    final count = _recent.length;
    _recent.clear();
    _send(
      'Map tiles failing: {} in {}s, zoom {}, {}, {}',
      [
        count,
        window.inSeconds,
        zoom,
        isOffline(error) ? 'looks like a network problem' : 'server refused',
        scrub('${error.runtimeType}: $error'),
      ],
    );
  }

  /// Removes the map key (and anything after it) and caps the length.
  static String scrub(String text) {
    var t = text.replaceAll(RegExp(r'key=[^&\s"]+'), 'key=***');
    // Tile addresses carry the position being viewed; drop them.
    t = t.replaceAll(RegExp(r'https?://\S+'), '<url>');
    return t.length > 160 ? t.substring(0, 160) : t;
  }
}

import 'package:flutter/material.dart';

/// One leg of the trail between two races, in screen coordinates.
class TrailLeg {
  final Offset from;
  final Offset to;

  /// True when either end is a planned race (drawn lighter and sparser).
  final bool planned;

  /// 0 (oldest) to 1 (newest): older legs fade so the direction is clear.
  final double strength;

  /// How many times this route was travelled; repeats are drawn once, a
  /// little bolder.
  final int repeats;
  const TrailLeg(this.from, this.to,
      {this.planned = false, this.strength = 1, this.repeats = 1});
}

/// A race on the trail, in date order.
class TrailStop {
  final String townKey;
  final Offset screen;
  final bool planned;
  const TrailStop(this.townKey, this.screen, {this.planned = false});
}

/// Joins consecutive stops in different towns. A route travelled more than
/// once (A to B, later B to A) becomes one leg that follows the newest trip,
/// and legs fade with age.
List<TrailLeg> buildLegs(List<TrailStop> stops) {
  final byRoute = <String, (TrailStop, TrailStop, int, int)>{};
  var order = 0;
  for (var i = 1; i < stops.length; i++) {
    final a = stops[i - 1], b = stops[i];
    if (a.townKey == b.townKey) continue;
    final key = a.townKey.compareTo(b.townKey) < 0
        ? '${a.townKey}|${b.townKey}'
        : '${b.townKey}|${a.townKey}';
    final seen = byRoute[key]?.$4 ?? 0;
    byRoute[key] = (a, b, order++, seen + 1);
  }
  final sorted = byRoute.values.toList()
    ..sort((x, y) => x.$3.compareTo(y.$3));
  final n = sorted.length;
  return [
    for (var i = 0; i < n; i++)
      TrailLeg(
        sorted[i].$1.screen,
        sorted[i].$2.screen,
        planned: sorted[i].$1.planned || sorted[i].$2.planned,
        strength: n <= 1 ? 1.0 : 0.25 + 0.75 * i / (n - 1),
        repeats: sorted[i].$4,
      ),
  ];
}

/// A faint dotted trail joining races in date order. The dots drift slowly
/// along each leg; with "reduce motion" on they stay still.
class JourneyTrail extends StatefulWidget {
  final List<TrailLeg> legs;
  const JourneyTrail({super.key, required this.legs});

  @override
  State<JourneyTrail> createState() => _JourneyTrailState();
}

class _JourneyTrailState extends State<JourneyTrail>
    with SingleTickerProviderStateMixin {
  // One dot spacing in ~0.33 s is about 30 px per second: slow and calm.
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 330));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (still) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: TrailPainter(widget.legs, _c),
          ),
        ),
      );
}

class TrailPainter extends CustomPainter {
  final List<TrailLeg> legs;
  final Animation<double> phase;
  TrailPainter(this.legs, this.phase) : super(repaint: phase);

  static const double spacing = 10;
  static const double plannedSpacing = 14;
  static const Color _blue = Color(0xFF0A3FA8);

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final dot = Paint()..style = PaintingStyle.fill;
    for (final leg in legs) {
      final bounds = Rect.fromPoints(leg.from, leg.to).inflate(8);
      if (!bounds.overlaps(screen)) continue;
      final d = leg.to - leg.from;
      final len = d.distance;
      if (len < 6) continue;
      final dir = d / len;
      final gap = leg.planned ? plannedSpacing : spacing;
      final fade = 0.35 + 0.65 * leg.strength;
      dot.color =
          _blue.withValues(alpha: (leg.planned ? 0.26 : 0.4) * fade);
      final r = (leg.planned ? 1.3 : 1.6) + (leg.repeats > 1 ? 0.5 : 0);
      // Start part-way along, so the dots appear to travel from A to B.
      var t = phase.value * gap;
      // Never draw an unbounded number of dots for a huge off-screen leg.
      const maxDots = 2000;
      var n = 0;
      while (t < len && n < maxDots) {
        final p = leg.from + dir * t;
        if (screen.inflate(4).contains(p)) canvas.drawCircle(p, r, dot);
        t += gap;
        n++;
      }
    }
  }

  @override
  bool shouldRepaint(TrailPainter old) => true;
}

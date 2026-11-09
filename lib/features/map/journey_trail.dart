import 'package:flutter/material.dart';

/// One leg of the trail between two races, in screen coordinates.
class TrailLeg {
  final Offset from;
  final Offset to;

  /// True when either end is a planned race (drawn lighter and sparser).
  final bool planned;
  const TrailLeg(this.from, this.to, {this.planned = false});
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
      dot.color = _blue.withValues(alpha: leg.planned ? 0.26 : 0.4);
      final r = leg.planned ? 1.3 : 1.6;
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
  bool shouldRepaint(TrailPainter old) => !identical(old.legs, legs);
}

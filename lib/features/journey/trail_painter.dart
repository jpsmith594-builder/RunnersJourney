import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/season_theme.dart';
import 'trail_layout.dart';

/// Paints the jungle background, foliage, seasonal particles and the trail.
class TrailPainter extends CustomPainter {
  final SeasonTheme theme;
  final TrailLayout layout;

  TrailPainter(this.theme, this.layout);

  @override
  void paint(Canvas canvas, Size size) {
    _sky(canvas, size);
    _particles(canvas, size);
    _foliage(canvas, size);
    _trail(canvas);
  }

  void _sky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [theme.skyTop, theme.skyBottom],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _particles(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    final paint = Paint()..color = theme.particle.withValues(alpha: 0.75);
    final count = (theme.particleCount * size.height / 800).round();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1.5 + rnd.nextDouble() * 2.5, paint);
    }
  }

  void _foliage(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final a = Paint()..color = theme.canopyA;
    final b = Paint()..color = theme.canopyB;
    var flip = false;
    for (double y = -10; y < size.height + 30; y += 30) {
      flip = !flip;
      final rl = 22 + rnd.nextDouble() * 26;
      final rr = 22 + rnd.nextDouble() * 26;
      final xl = -8 + rnd.nextDouble() * 34;
      final xr = size.width + 8 - rnd.nextDouble() * 34;
      canvas.drawCircle(Offset(xl, y), rl, flip ? a : b);
      canvas.drawCircle(Offset(xr, y + 12), rr, flip ? b : a);
      if (rnd.nextDouble() < 0.4) {
        canvas.drawCircle(Offset(xl + 22, y + 8), rl * 0.55, flip ? b : a);
      }
      if (rnd.nextDouble() < 0.4) {
        canvas.drawCircle(Offset(xr - 22, y + 4), rr * 0.55, flip ? a : b);
      }
    }
  }

  Path _segment(Offset p0, Offset p1) {
    final midY = (p0.dy + p1.dy) / 2;
    return Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(p0.dx, midY, p1.dx, midY, p1.dx, p1.dy);
  }

  void _trail(Canvas canvas) {
    final pts = <Offset>[layout.start, ...layout.points.map((p) => p.pos)];

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18
      ..color = Colors.black.withValues(alpha: 0.25);
    final done = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12
      ..color = theme.pathDone;
    final planned = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..color = theme.pathPlanned.withValues(alpha: 0.8);

    for (var j = 0; j < pts.length - 1; j++) {
      final path = _segment(pts[j], pts[j + 1]);
      if (layout.points[j].passed) {
        canvas.drawPath(path, edge);
        canvas.drawPath(path, done);
      } else {
        _dashed(canvas, path, planned);
      }
    }

    // Trailhead marker
    canvas.drawCircle(layout.start, 10, Paint()..color = theme.pathDone);
    canvas.drawCircle(
      layout.start,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
  }

  void _dashed(Canvas canvas, Path path, Paint paint,
      {double dash = 14, double gap = 12}) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = math.min(d + dash, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant TrailPainter old) =>
      old.theme.season != theme.season || old.layout != layout;
}

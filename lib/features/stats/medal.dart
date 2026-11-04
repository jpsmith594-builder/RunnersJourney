import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'badges.dart';

enum MedalTier { bronze, silver, gold, platinum }

extension MedalTierInfo on MedalTier {
  String get label {
    switch (this) {
      case MedalTier.bronze:
        return 'BRONZE';
      case MedalTier.silver:
        return 'SILVER';
      case MedalTier.gold:
        return 'GOLD';
      case MedalTier.platinum:
        return 'PLATINUM';
    }
  }

  /// Colours of the metal rim, light to dark and back.
  List<Color> get metal {
    switch (this) {
      case MedalTier.bronze:
        return const [
          Color(0xFFFFC38A), Color(0xFFC8742F), Color(0xFF7A3E12), Color(0xFFEFA562)
        ];
      case MedalTier.silver:
        return const [
          Color(0xFFFFFFFF), Color(0xFFBCC6D2), Color(0xFF7D8997), Color(0xFFEAEFF4)
        ];
      case MedalTier.gold:
        return const [
          Color(0xFFFFF3AE), Color(0xFFFFBE1F), Color(0xFFB87800), Color(0xFFFFDD55)
        ];
      case MedalTier.platinum:
        return const [
          Color(0xFFF7F2FF), Color(0xFF9FB4FF), Color(0xFF6A4DF0), Color(0xFFE2D6FF)
        ];
    }
  }
}

/// How hard each badge is, which sets its metal.
MedalTier tierOf(String badgeId) {
  switch (badgeId) {
    case 'races50':
    case 'km1000':
    case 'ultra':
    case 'sub4':
    case 'comrades':
      return MedalTier.platinum;
    case 'races25':
    case 'firstmarathon':
    case 'sub2':
    case 'prov5':
    case 'towns10':
      return MedalTier.gold;
    case 'races10':
    case 'km500':
    case 'firsthalf':
    case 'sub60':
    case 'prov3':
    case 'twooceans':
      return MedalTier.silver;
    default:
      return MedalTier.bronze;
  }
}

Color _lighten(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Color _darken(Color c, double t) => Color.lerp(c, Colors.black, t)!;

const _grey = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

/// A shiny medal on a ribbon. Earned medals are vibrant and sparkle; locked
/// ones are grey with a small padlock.
class Medal extends StatelessWidget {
  final RunnerBadge badge;
  final bool earned;
  final double size; // width; the height is 1.2x

  const Medal({
    super.key,
    required this.badge,
    required this.earned,
    this.size = 90,
  });

  @override
  Widget build(BuildContext context) {
    final h = size * 1.2;
    final r = size * 0.40;
    final iconSize = r * 0.95;
    final cy = h * 0.64;
    Widget medal = SizedBox(
      width: size,
      height: h,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MedalPainter(
                color: badge.color,
                tier: tierOf(badge.id),
                sparkle: earned,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: cy - iconSize / 2,
            child: Center(
              child: Icon(
                badge.icon,
                size: iconSize,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (earned) return medal;
    medal = Opacity(
      opacity: 0.55,
      child: ColorFiltered(colorFilter: _grey, child: medal),
    );
    return SizedBox(
      width: size,
      height: h,
      child: Stack(
        children: [
          medal,
          Positioned(
            right: size * 0.08,
            bottom: h * 0.06,
            child: CircleAvatar(
              radius: size * 0.12,
              backgroundColor: Colors.black54,
              child: Icon(Icons.lock, size: size * 0.14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  final Color color;
  final MedalTier tier;
  final bool sparkle;
  const _MedalPainter(
      {required this.color, required this.tier, required this.sparkle});

  Path _seal(Offset c, double radius, int bumps, double depth) {
    final p = Path();
    const steps = 240;
    for (var i = 0; i <= steps; i++) {
      final a = 2 * math.pi * i / steps;
      final rr = radius * (1 + depth * math.cos(bumps * a));
      final pt = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p..close();
  }

  Path _star(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
    ..close();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final cx = w / 2;
    final cy = h * 0.64;
    final r = w * 0.40;
    final centre = Offset(cx, cy);

    // Ribbon: two straps crossing behind the medal.
    final left = Path()
      ..moveTo(cx - r * 0.85, 0)
      ..lineTo(cx - r * 0.30, 0)
      ..lineTo(cx + r * 0.25, cy)
      ..lineTo(cx - r * 0.30, cy)
      ..close();
    final right = Path()
      ..moveTo(cx + r * 0.85, 0)
      ..lineTo(cx + r * 0.30, 0)
      ..lineTo(cx - r * 0.25, cy)
      ..lineTo(cx + r * 0.30, cy)
      ..close();
    canvas.drawPath(
        left,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_lighten(color, 0.25), _darken(color, 0.1)],
          ).createShader(Rect.fromLTWH(0, 0, w, cy)));
    canvas.drawPath(
        right,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_darken(color, 0.1), _darken(color, 0.38)],
          ).createShader(Rect.fromLTWH(0, 0, w, cy)));
    final stripe = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = w * 0.012
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - r * 0.575, 0), Offset(cx - r * 0.025, cy), stripe);
    canvas.drawLine(Offset(cx + r * 0.575, 0), Offset(cx + r * 0.025, cy), stripe);

    // Medal body with a scalloped metal edge.
    final seal = _seal(centre, r, 20, 0.035);
    canvas.drawShadow(seal, Colors.black, 6, true);
    final metal = tier.metal;
    canvas.drawPath(
      seal,
      Paint()
        ..shader = SweepGradient(
          colors: [...metal, metal.first],
          transform: const GradientRotation(-math.pi / 4),
        ).createShader(Rect.fromCircle(center: centre, radius: r)),
    );
    canvas.drawPath(
      seal,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.01
        ..color = _darken(metal[2], 0.25),
    );

    // Coloured face.
    final face = r * 0.78;
    canvas.drawCircle(
      centre,
      face,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.05,
          colors: [_lighten(color, 0.38), color, _darken(color, 0.3)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: centre, radius: face)),
    );
    canvas.drawCircle(
      centre,
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012
        ..color = _lighten(metal[0], 0.2),
    );
    canvas.drawCircle(
      centre,
      face * 0.86,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.007
        ..color = Colors.white.withValues(alpha: 0.45),
    );

    // Glossy shine across the upper left.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: centre, radius: face)));
    canvas.drawRect(
      Rect.fromCircle(center: centre, radius: face),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55],
        ).createShader(Rect.fromCircle(center: centre, radius: face)),
    );
    canvas.restore();

    if (sparkle) {
      final p = Paint()..color = Colors.white;
      canvas.drawPath(_star(Offset(cx + r * 0.95, cy - r * 0.85), w * 0.075), p);
      canvas.drawPath(_star(Offset(cx - r * 1.0, cy + r * 0.25), w * 0.05), p);
      canvas.drawPath(_star(Offset(cx + r * 0.7, cy + r * 0.95), w * 0.04), p);
    }
  }

  @override
  bool shouldRepaint(covariant _MedalPainter old) =>
      old.color != color || old.tier != tier || old.sparkle != sparkle;
}

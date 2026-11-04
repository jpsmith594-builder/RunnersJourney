import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'badges.dart';

enum CrestTier { bronze, silver, gold, platinum, diamond }

extension CrestTierInfo on CrestTier {
  String get label {
    switch (this) {
      case CrestTier.bronze:
        return 'BRONZE';
      case CrestTier.silver:
        return 'SILVER';
      case CrestTier.gold:
        return 'GOLD';
      case CrestTier.platinum:
        return 'PLATINUM';
      case CrestTier.diamond:
        return 'DIAMOND';
    }
  }

  /// Number of stars shown at the top of the crest.
  int get stars => index + 1;

  /// Colours of the metal border: highlight, mid, shadow, back to light.
  List<Color> get metal {
    switch (this) {
      case CrestTier.bronze:
        return const [
          Color(0xFFFFC38A), Color(0xFFC8742F), Color(0xFF7A3E12), Color(0xFFEFA562)
        ];
      case CrestTier.silver:
        return const [
          Color(0xFFFFFFFF), Color(0xFFBCC6D2), Color(0xFF7D8997), Color(0xFFEAEFF4)
        ];
      case CrestTier.gold:
        return const [
          Color(0xFFFFF3AE), Color(0xFFFFBE1F), Color(0xFFB87800), Color(0xFFFFDD55)
        ];
      case CrestTier.platinum:
        return const [
          Color(0xFFF7F2FF), Color(0xFF9FB4FF), Color(0xFF6A4DF0), Color(0xFFE2D6FF)
        ];
      case CrestTier.diamond:
        return const [
          Color(0xFFE9FFFF), Color(0xFF4DE0FF), Color(0xFF2A7BFF), Color(0xFFB8F3FF)
        ];
    }
  }
}

/// How hard each badge is, which sets its metal and stars.
CrestTier crestTierOf(String badgeId) {
  switch (badgeId) {
    case 'sub40':
    case 'sub90':
    case 'sub3':
      return CrestTier.diamond;
    case 'races50':
    case 'km1000':
    case 'ultra':
    case 'sub4':
    case 'comrades':
      return CrestTier.platinum;
    case 'races25':
    case 'firstmarathon':
    case 'sub2':
    case 'prov5':
    case 'towns10':
      return CrestTier.gold;
    case 'races10':
    case 'km500':
    case 'firsthalf':
    case 'sub60':
    case 'prov3':
    case 'twooceans':
      return CrestTier.silver;
    default:
      return CrestTier.bronze;
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

/// A badge crest: a shield with a metal border that catches the light, stars
/// for how hard it is, and the badge's icon. Earned crests are vivid and
/// sparkle; locked ones are grey with a small padlock.
class Crest extends StatelessWidget {
  final RunnerBadge badge;
  final bool earned;
  final double size; // width; the height is 1.2x

  const Crest({
    super.key,
    required this.badge,
    required this.earned,
    this.size = 90,
  });

  @override
  Widget build(BuildContext context) {
    final h = size * 1.2;
    final iconSize = size * 0.34;
    Widget crest = SizedBox(
      width: size,
      height: h,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CrestPainter(
                color: badge.color,
                tier: crestTierOf(badge.id),
                sparkle: earned,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: h * 0.54 - iconSize / 2,
            child: Center(
              child: Icon(
                badge.icon,
                size: iconSize,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Color(0x73000000), blurRadius: 5, offset: Offset(0, 2))
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (earned) return crest;
    crest = Opacity(
      opacity: 0.55,
      child: ColorFiltered(colorFilter: _grey, child: crest),
    );
    return SizedBox(
      width: size,
      height: h,
      child: Stack(
        children: [
          crest,
          Positioned(
            right: size * 0.06,
            bottom: h * 0.20,
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

class _CrestPainter extends CustomPainter {
  final Color color;
  final CrestTier tier;
  final bool sparkle;
  const _CrestPainter(
      {required this.color, required this.tier, required this.sparkle});

  Path _shield(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(w * 0.08, h * 0.15)
      ..quadraticBezierTo(w * 0.5, -h * 0.03, w * 0.92, h * 0.15)
      ..lineTo(w * 0.92, h * 0.54)
      ..cubicTo(w * 0.92, h * 0.78, w * 0.68, h * 0.90, w * 0.5, h * 0.985)
      ..cubicTo(w * 0.32, h * 0.90, w * 0.08, h * 0.78, w * 0.08, h * 0.54)
      ..close();
  }

  Path _scaled(Path p, Size s, double k) {
    final cx = s.width / 2, cy = s.height * 0.52;
    final m = Matrix4.identity()
      ..translate(cx, cy)
      ..scale(k, k)
      ..translate(-cx, -cy);
    return p.transform(m.storage);
  }

  Path _star(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.42;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p..close();
  }

  Path _spark(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
    ..close();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final rect = Offset.zero & s;
    final outer = _shield(s);
    final metal = tier.metal;

    canvas.drawShadow(outer, Colors.black, 7, true);

    // Metal body of the crest (the border area), brushed with a diagonal gradient.
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [metal[0], metal[1], metal[2], metal[3]],
          stops: const [0.0, 0.35, 0.75, 1.0],
        ).createShader(rect),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012
        ..color = _darken(metal[2], 0.3),
    );

    // Coloured face inside the border.
    final face = _scaled(outer, s, 0.80);
    canvas.drawPath(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_lighten(color, 0.30), color, _darken(color, 0.38)],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // Soft chevron stripes on the face for a modern, crest-like texture.
    canvas.save();
    canvas.clipPath(face);
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.10);
    for (var i = 0; i < 4; i++) {
      final y = h * (0.58 + i * 0.13);
      canvas.drawPath(
        Path()
          ..moveTo(0, y)
          ..lineTo(w * 0.5, y + h * 0.10)
          ..lineTo(w, y)
          ..lineTo(w, y + h * 0.05)
          ..lineTo(w * 0.5, y + h * 0.15)
          ..lineTo(0, y + h * 0.05)
          ..close(),
        stripe,
      );
    }
    canvas.restore();

    // Inner edge lines: a dark groove and a bright line.
    canvas.drawPath(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014
        ..color = _darken(metal[2], 0.35),
    );
    canvas.drawPath(
      _scaled(outer, s, 0.74),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.008
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    // Tier stars across the top of the face.
    final n = tier.stars;
    final starR = w * 0.055;
    final gap = starR * 2.5;
    final startX = w / 2 - gap * (n - 1) / 2;
    for (var i = 0; i < n; i++) {
      final c = Offset(startX + gap * i, h * 0.255 + (i - (n - 1) / 2).abs() * h * 0.012);
      canvas.drawPath(
          _star(c.translate(0, w * 0.01), starR),
          Paint()..color = Colors.black.withValues(alpha: 0.25));
      canvas.drawPath(
        _star(c, starR),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF7C2), Color(0xFFFFC21F)],
          ).createShader(Rect.fromCircle(center: c, radius: starR)),
      );
    }

    // Glossy shine across the upper left of the face.
    canvas.save();
    canvas.clipPath(face);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.50),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5],
        ).createShader(rect),
    );
    canvas.restore();

    // Shine on the border: bright at the top left, fading away along the edge.
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55],
        ).createShader(rect),
    );

    if (sparkle) {
      final p = Paint()..color = Colors.white;
      canvas.drawPath(_spark(Offset(w * 0.95, h * 0.16), w * 0.075), p);
      canvas.drawPath(_spark(Offset(w * 0.04, h * 0.50), w * 0.05), p);
      canvas.drawPath(_spark(Offset(w * 0.86, h * 0.80), w * 0.04), p);
    }
  }

  @override
  bool shouldRepaint(covariant _CrestPainter old) =>
      old.color != color || old.tier != tier || old.sparkle != sparkle;
}

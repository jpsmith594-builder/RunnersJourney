import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'badges.dart';

enum CrestTier { bronze, silver, gold, platinum, titanium }

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
      case CrestTier.titanium:
        return 'TITANIUM';
    }
  }

  /// Number of stars shown at the top of the crest.
  int get stars => index + 1;

  /// Four key colours of the metal: highlight, mid, shadow, light again.
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
      case CrestTier.titanium:
        return const [
          Color(0xFFE6ECF5), Color(0xFF7F8CA3), Color(0xFF2E3544), Color(0xFFB7C2D4)
        ];
    }
  }

  /// Seven colours that alternate light and dark, which makes a gradient
  /// look like brushed metal.
  List<Color> get brushed {
    switch (this) {
      case CrestTier.bronze:
        return const [
          Color(0xFFFFD1A1), Color(0xFFB8631F), Color(0xFFF2AE6C), Color(0xFF7A3E12),
          Color(0xFFE59A55), Color(0xFF5E2D0B), Color(0xFFFFC48A)
        ];
      case CrestTier.silver:
        return const [
          Color(0xFFFFFFFF), Color(0xFF9AA6B5), Color(0xFFE9EEF4), Color(0xFF6B7684),
          Color(0xFFD5DCE5), Color(0xFF58626F), Color(0xFFF7FAFD)
        ];
      case CrestTier.gold:
        return const [
          Color(0xFFFFF6B8), Color(0xFFE29E00), Color(0xFFFFE27A), Color(0xFF9A6200),
          Color(0xFFFFD34D), Color(0xFF7A4B00), Color(0xFFFFEC9A)
        ];
      case CrestTier.platinum:
        return const [
          Color(0xFFFFFFFF), Color(0xFF8E9BFF), Color(0xFFE3DCFF), Color(0xFF5B45D6),
          Color(0xFFC9BEFF), Color(0xFF3D2A9E), Color(0xFFF1EDFF)
        ];
      case CrestTier.titanium:
        return const [
          Color(0xFFF2F6FC), Color(0xFF5E6B82), Color(0xFFB9C4D6), Color(0xFF29303D),
          Color(0xFF8D9AB0), Color(0xFF1A1F29), Color(0xFFDCE4F0)
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
      return CrestTier.titanium;
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
    final iconSize = size * 0.36;
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
            top: h * 0.50 - iconSize / 2,
            child: Center(
              child: Icon(
                badge.icon,
                size: iconSize,
                color: Colors.white,
                shadows: [
                  Shadow(
                      color: _lighten(badge.color, 0.6),
                      blurRadius: size * 0.12),
                  const Shadow(
                      color: Color(0x99000000),
                      blurRadius: 4,
                      offset: Offset(0, 2)),
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
            bottom: h * 0.18,
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

  /// Angular shield with a notch at the top and a pointed base.
  Path _shield(Size s) {
    final w = s.width, h = s.height;
    Offset o(double x, double y) => Offset(w * x, h * y);
    return Path()
      ..moveTo(o(0.17, 0.04).dx, o(0.17, 0.04).dy)
      ..lineTo(o(0.41, 0.04).dx, o(0.41, 0.04).dy)
      ..lineTo(o(0.50, 0.105).dx, o(0.50, 0.105).dy)
      ..lineTo(o(0.59, 0.04).dx, o(0.59, 0.04).dy)
      ..lineTo(o(0.83, 0.04).dx, o(0.83, 0.04).dy)
      ..lineTo(o(0.97, 0.18).dx, o(0.97, 0.18).dy)
      ..lineTo(o(0.97, 0.58).dx, o(0.97, 0.58).dy)
      ..lineTo(o(0.50, 0.99).dx, o(0.50, 0.99).dy)
      ..lineTo(o(0.03, 0.58).dx, o(0.03, 0.58).dy)
      ..lineTo(o(0.03, 0.18).dx, o(0.03, 0.18).dy)
      ..close();
  }

  Path _scaled(Path p, Size s, double k, {double dy = 0}) {
    final cx = s.width / 2, cy = s.height * 0.50;
    final m = Matrix4.identity()
      ..translate(cx, cy + dy)
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

  Path _hexagon(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
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

  /// Diagonal hairlines across the whole canvas; the caller clips them.
  void _hatch(Canvas canvas, Size s, Color c, double spacing, double width) {
    final p = Paint()
      ..color = c
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    final d = s.height + s.width;
    for (var x = -s.height; x < d; x += spacing) {
      canvas.drawLine(Offset(x, s.height), Offset(x + s.height, 0), p);
    }
  }

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final rect = Offset.zero & s;
    final outer = _shield(s);
    final bevel = _scaled(outer, s, 0.90);
    final face = _scaled(outer, s, 0.82);
    final ring = Path.combine(PathOperation.difference, outer, face);
    final brushed = tier.brushed;
    final metal = tier.metal;

    // Soft coloured glow and drop shadow.
    canvas.drawPath(
      outer,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.07),
    );
    canvas.drawShadow(outer, Colors.black, 6, true);

    // Frame: brushed metal with fine hairlines.
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: brushed,
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipPath(ring);
    _hatch(canvas, s, Colors.black.withValues(alpha: 0.16), w * 0.032, w * 0.006);
    _hatch(canvas, s, Colors.white.withValues(alpha: 0.30), w * 0.032, w * 0.004);
    canvas.restore();

    // Bevel: a second ring that is bright on the top left and dark on the
    // bottom right, so the frame looks cut from solid metal.
    canvas.drawPath(
      bevel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.022
        ..strokeJoin = StrokeJoin.miter
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.95),
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.55),
          ],
          stops: const [0.0, 0.5, 0.5, 1.0],
        ).createShader(rect),
    );
    // Outer edge lines.
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014
        ..strokeJoin = StrokeJoin.miter
        ..color = _darken(metal[2], 0.45),
    );

    // Face: deep at the bottom, vivid and bright at the top.
    canvas.drawPath(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            _darken(color, 0.62),
            _darken(color, 0.25),
            color,
            _lighten(color, 0.38),
          ],
          stops: const [0.0, 0.35, 0.72, 1.0],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipPath(face);

    // Light bloom behind the emblem.
    final emblem = Offset(w / 2, h * 0.50);
    canvas.drawCircle(
      emblem,
      w * 0.46,
      Paint()
        ..shader = RadialGradient(colors: [
          _lighten(color, 0.55).withValues(alpha: 0.75),
          _lighten(color, 0.55).withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: emblem, radius: w * 0.46)),
    );
    // Feint hairlines and chevrons on the face.
    _hatch(canvas, s, Colors.white.withValues(alpha: 0.07), w * 0.05, w * 0.004);
    final chev = Paint()..color = Colors.white.withValues(alpha: 0.13);
    for (var i = 0; i < 3; i++) {
      final y = h * (0.70 + i * 0.075);
      canvas.drawPath(
        Path()
          ..moveTo(0, y)
          ..lineTo(w * 0.5, y + h * 0.13)
          ..lineTo(w, y)
          ..lineTo(w, y + h * 0.025)
          ..lineTo(w * 0.5, y + h * 0.155)
          ..lineTo(0, y + h * 0.025)
          ..close(),
        chev,
      );
    }
    canvas.restore();

    // Face edge: a dark groove with a thin bright line just inside it.
    canvas.drawPath(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014
        ..strokeJoin = StrokeJoin.miter
        ..color = _darken(metal[2], 0.5),
    );
    canvas.drawPath(
      _scaled(outer, s, 0.785),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.007
        ..strokeJoin = StrokeJoin.miter
        ..color = metal[0].withValues(alpha: 0.85),
    );

    // Emblem plate: a metal-edged hexagon the icon sits on.
    final plate = _hexagon(emblem, w * 0.285);
    canvas.drawPath(plate, Paint()..color = Colors.black.withValues(alpha: 0.32));
    canvas.drawPath(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.022
        ..strokeJoin = StrokeJoin.miter
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: brushed,
        ).createShader(Rect.fromCircle(center: emblem, radius: w * 0.3)),
    );
    canvas.drawPath(
      _hexagon(emblem, w * 0.25),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.005
        ..color = Colors.white.withValues(alpha: 0.4),
    );

    // Tier stars across the top of the face.
    final n = tier.stars;
    final starR = w * 0.052;
    final gap = starR * 2.5;
    final startX = w / 2 - gap * (n - 1) / 2;
    for (var i = 0; i < n; i++) {
      final c = Offset(startX + gap * i, h * 0.215);
      canvas.drawPath(_star(c.translate(0, w * 0.012), starR),
          Paint()..color = Colors.black.withValues(alpha: 0.35));
      canvas.drawPath(
        _star(c, starR),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBD6), Color(0xFFFFC21F)],
          ).createShader(Rect.fromCircle(center: c, radius: starR)),
      );
    }

    // Light sweeps across the whole crest: one wide and faint, one thin and sharp.
    canvas.save();
    canvas.clipPath(outer);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.18, 0.34, 0.50],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.50, 0.545, 0.59],
        ).createShader(rect),
    );
    canvas.restore();

    // Border shine: bright at the top left and fading along the edge.
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..strokeJoin = StrokeJoin.miter
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 1.0),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5],
        ).createShader(rect),
    );

    // Rivets at the corners of the frame.
    for (final p in [
      Offset(w * 0.105, h * 0.115),
      Offset(w * 0.895, h * 0.115),
    ]) {
      canvas.drawCircle(p, w * 0.017, Paint()..color = _darken(metal[2], 0.4));
      canvas.drawCircle(p.translate(-w * 0.003, -w * 0.003), w * 0.011,
          Paint()..color = metal[0]);
    }

    if (sparkle) {
      final p = Paint()..color = Colors.white;
      canvas.drawPath(_spark(Offset(w * 0.97, h * 0.10), w * 0.08), p);
      canvas.drawPath(_spark(Offset(w * 0.03, h * 0.46), w * 0.05), p);
      canvas.drawPath(_spark(Offset(w * 0.88, h * 0.80), w * 0.04), p);
    }
  }

  @override
  bool shouldRepaint(covariant _CrestPainter old) =>
      old.color != color || old.tier != tier || old.sparkle != sparkle;
}

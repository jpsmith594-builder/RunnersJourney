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
    case 'country5':
    case 'races25':
    case 'firstmarathon':
    case 'sub2':
    case 'prov5':
    case 'towns10':
      return CrestTier.gold;
    case 'country2':
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
    final iconSize = size * 0.27;
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
            bottom: h * 0.24,
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

/// Crest artwork in a 100 x 120 box (left half; the right is mirrored).
const _shieldD = 'M24 33 Q50 19 76 33 L76 64 C76 84 62 95 50 104 C38 95 24 84 24 64 Z';
const _scrollsD = [
  ['M31 92 C12 90 5 68 12 54 C15 47 14 40 19 36 L19.0 34.3 L20.2 35.4 L21.6 36.1 L23.2 36.2 L24.6 35.7 L25.7 34.8 L26.4 33.6 L26.6 32.3 L26.3 31.0 L25.6 30.0 L24.7 29.3 L23.6 29.1 L22.5 29.2 L21.7 29.7 L21.0 30.4 L20.7 31.2 L20.7 32.1 L21.1 32.8 L21.6 33.4 L22.2 33.6 L22.9 33.7 L23.4 33.5 L23.8 33.1 L24.0 32.7 L24.1 32.2 L23.9 31.8 L23.7 31.6', 3.4],
  ['M13 56 C5 55 2 47 6 42 L6.6 39.8 L6.5 41.0 L6.8 42.1 L7.4 43.0 L8.3 43.7 L9.3 44.0 L10.3 43.9 L11.2 43.5 L11.9 42.9 L12.3 42.1 L12.5 41.3 L12.3 40.5 L11.9 39.8 L11.3 39.3 L10.7 39.1 L10.0 39.1 L9.4 39.3 L8.9 39.7 L8.6 40.2 L8.5 40.7 L8.6 41.2 L8.9 41.6 L9.2 41.8 L9.6 41.9 L9.9 41.9 L10.2 41.8 L10.4 41.6', 2.6],
  ['M48 109 C40 102 29 103 21 108 L21.1 107.6 L19.7 108.0 L18.2 107.9 L17.0 107.2 L16.1 106.2 L15.6 105.0 L15.6 103.7 L16.0 102.6 L16.8 101.7 L17.8 101.2 L18.9 101.1 L19.9 101.4 L20.7 102.0 L21.2 102.8 L21.3 103.6 L21.2 104.4 L20.8 105.1 L20.2 105.6 L19.5 105.8 L18.9 105.7 L18.3 105.4 L18.0 105.0 L17.8 104.5 L17.8 104.0 L18.0 103.7 L18.3 103.4 L18.6 103.3', 3.2],
  ['M26 104.5 C20 99 18 93 22 90 L22.0 91.5 L22.4 90.6 L23.0 90.0 L23.8 89.6 L24.6 89.4 L25.4 89.5 L26.1 89.8 L26.7 90.4 L27.0 91.0 L27.1 91.7 L27.0 92.4 L26.8 92.9 L26.3 93.4 L25.8 93.6 L25.2 93.7 L24.7 93.6 L24.3 93.3 L24.0 93.0 L23.8 92.6 L23.8 92.2 L23.9 91.8 L24.1 91.5 L24.3 91.3 L24.6 91.2 L24.9 91.2 L25.1 91.3 L25.3 91.5', 2.2],
];
const _fleurD = 'M0 -10 C3.4 -5.5 3.2 -0.5 0 4 C-3.2 -0.5 -3.4 -5.5 0 -10 Z M-1 2.5 C-5.5 4 -9 -0.5 -7.6 -4.6 C-5.8 -1.4 -3.4 -1.4 -1 -3.2 Z M1 2.5 C5.5 4 9 -0.5 7.6 -4.6 C5.8 -1.4 3.4 -1.4 1 -3.2 Z M-4.2 3.6 H4.2 V5.8 H-4.2 Z M0 6 L-2 10.5 L0 9 L2 10.5 Z';
const _crownD = 'M31 30 L29 13 L36 20 L38 11 L44 20 L50 9 L56 20 L62 11 L64 20 L71 13 L69 30 C60 34 40 34 31 30 Z';
const _crownBandD = 'M31 26 C40 30 60 30 69 26 L69 32 C60 36 40 36 31 32 Z';

/// Minimal parser for the absolute M, L, H, C, Q and Z path commands.
Path _parsePath(String d) {
  final tokens = RegExp(r'[MLHCQZ]|-?\d+\.?\d*')
      .allMatches(d)
      .map((m) => m.group(0)!)
      .toList();
  final p = Path();
  var i = 0;
  double n() => double.parse(tokens[i++]);
  var cy = 0.0;
  while (i < tokens.length) {
    final c = tokens[i++];
    switch (c) {
      case 'M':
        final x = n();
        cy = n();
        p.moveTo(x, cy);
        break;
      case 'L':
        final x = n();
        cy = n();
        p.lineTo(x, cy);
        break;
      case 'H':
        final x = n();
        p.lineTo(x, cy);
        break;
      case 'C':
        p.cubicTo(n(), n(), n(), n(), n(), n());
        break;
      case 'Q':
        p.quadraticBezierTo(n(), n(), n(), n());
        break;
      case 'Z':
        p.close();
        break;
    }
  }
  return p;
}

class _CrestPainter extends CustomPainter {
  final Color color;
  final CrestTier tier;
  final bool sparkle;
  const _CrestPainter(
      {required this.color, required this.tier, required this.sparkle});

  static final Path _shield = _parsePath(_shieldD);
  static final Path _fleur = _parsePath(_fleurD);
  static final Path _crown = _parsePath(_crownD);
  static final Path _crownBand = _parsePath(_crownBandD);
  static final List<Path> _scrolls = [
    for (final s in _scrollsD) _parsePath(s[0] as String)
  ];

  static Path _xf(Path p, double x, double y, double k, {double rot = 0}) {
    final m = Matrix4.identity()
      ..translate(x, y)
      ..rotateZ(rot)
      ..scale(k, k);
    return p.transform(m.storage);
  }

  Path _grow(Path p, double k) {
    final m = Matrix4.identity()
      ..translate(50.0, 62.0)
      ..scale(k, k)
      ..translate(-50.0, -62.0);
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

  void _hatch(Canvas canvas, Color c, double spacing, double width) {
    final p = Paint()
      ..color = c
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    for (var x = -120.0; x < 120; x += spacing) {
      canvas.drawLine(Offset(x, 120), Offset(x + 120, 0), p);
    }
  }

  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    canvas.scale(s.width / 100, s.height / 120);
    const box = Rect.fromLTWH(0, 0, 100, 120);
    final metal = tier.metal;
    final dark = _darken(metal[2], 0.62);
    final metalShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: tier.brushed,
    ).createShader(box);
    Paint fill() => Paint()..shader = metalShader;

    // Glow behind everything.
    canvas.drawPath(
      _shield,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // Scroll flourishes, drawn on the left and mirrored on the right.
    void scrolls() {
      for (var i = 0; i < _scrolls.length; i++) {
        final w = (_scrollsD[i][1] as double);
        final base = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        base
          ..strokeWidth = w + 0.9
          ..color = dark;
        canvas.drawPath(_scrolls[i], base);
        canvas.drawPath(
            _scrolls[i],
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = w
              ..shader = metalShader);
        canvas.save();
        canvas.translate(-0.4, -0.4);
        canvas.drawPath(
            _scrolls[i],
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = w * 0.22
              ..color = Colors.white.withValues(alpha: 0.7));
        canvas.restore();
      }
    }

    scrolls();
    canvas.save();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    scrolls();
    canvas.restore();

    // Shield frame: brushed metal with hairlines and a bevelled edge.
    final face = _grow(_shield, 0.84);
    final ring = Path.combine(PathOperation.difference, _shield, face);
    canvas.drawShadow(_shield, Colors.black, 2, true);
    canvas.drawPath(_shield, fill());
    canvas.save();
    canvas.clipPath(ring);
    _hatch(canvas, Colors.black.withValues(alpha: 0.16), 2.6, 0.4);
    _hatch(canvas, Colors.white.withValues(alpha: 0.3), 2.6, 0.25);
    canvas.restore();
    canvas.drawPath(
      _grow(_shield, 0.92),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
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
        ).createShader(box),
    );
    canvas.drawPath(
        _shield,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = dark);

    // Face: dark in the bottom-left corner, fading to bright at the top right.
    canvas.drawPath(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            _darken(color, 0.72),
            _darken(color, 0.40),
            color,
            _lighten(color, 0.45),
          ],
          stops: const [0.0, 0.30, 0.66, 1.0],
        ).createShader(box),
    );
    canvas.save();
    canvas.clipPath(face);
    canvas.drawRect(
      box,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.topLeft,
          radius: 0.9,
          colors: [
            _darken(color, 0.6).withValues(alpha: 0.55),
            _darken(color, 0.6).withValues(alpha: 0.0),
          ],
        ).createShader(box),
    );
    // Bloom behind the emblem.
    const em = Offset(50, 60);
    canvas.drawCircle(
      em,
      30,
      Paint()
        ..shader = RadialGradient(colors: [
          _lighten(color, 0.55).withValues(alpha: 0.7),
          _lighten(color, 0.55).withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: em, radius: 30)),
    );
    _hatch(canvas, Colors.white.withValues(alpha: 0.07), 4.5, 0.3);
    // Centre ridge: the left half catches the light, the right half is in shade.
    canvas.drawRect(const Rect.fromLTWH(50, 0, 50, 120),
        Paint()..color = Colors.black.withValues(alpha: 0.18));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 50, 120),
        Paint()..color = Colors.white.withValues(alpha: 0.07));
    canvas.restore();
    canvas.drawLine(
        const Offset(50, 29), const Offset(50, 100),
        Paint()
          ..strokeWidth = 0.35
          ..color = metal[0].withValues(alpha: 0.6));
    canvas.drawPath(
        face,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = dark);
    canvas.drawPath(
        _grow(_shield, 0.8),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4
          ..color = metal[0].withValues(alpha: 0.85));

    // Round plate behind the emblem.
    canvas.drawCircle(em, 14.5, Paint()..color = Colors.black.withValues(alpha: 0.32));
    canvas.drawCircle(
        em,
        14.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..shader = metalShader);
    canvas.drawCircle(
        em,
        12.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.3
          ..color = Colors.white.withValues(alpha: 0.45));

    // Tier stars across the top of the face.
    final n = tier.stars;
    const starR = 2.6;
    const gap = starR * 2.5;
    final startX = 50 - gap * (n - 1) / 2;
    for (var i = 0; i < n; i++) {
      final c = Offset(startX + gap * i, 42);
      canvas.drawPath(_star(c.translate(0, 0.6), starR),
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

    // Light sweep across the shield.
    canvas.save();
    canvas.clipPath(_shield);
    canvas.drawRect(
      box,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.2, 0.34, 0.48],
        ).createShader(box),
    );
    canvas.restore();

    // Crown.
    final crownEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeJoin = StrokeJoin.round
      ..color = dark;
    canvas.drawShadow(_crown, Colors.black, 1.5, true);
    canvas.drawPath(_crown, fill());
    canvas.drawPath(_crown, crownEdge);
    for (final p in const [
      Offset(29, 12.5), Offset(38, 10.5), Offset(62, 10.5), Offset(71, 12.5)
    ]) {
      canvas.drawCircle(p, 1.5, fill());
      canvas.drawCircle(p, 1.5, crownEdge..strokeWidth = 0.3);
    }
    canvas.drawPath(_crownBand, fill());
    canvas.drawPath(_crownBand, crownEdge..strokeWidth = 0.5);
    // Jewels on the band.
    for (final x in const [38.0, 50.0, 62.0]) {
      canvas.drawCircle(Offset(x, 31.3 + (x == 50 ? 0.9 : 0.0)), 1.1,
          Paint()..color = _lighten(color, 0.35));
    }
    // Fleur-de-lis on top of the crown and at the foot of the crest.
    for (final f in [
      _xf(_fleur, 50, 11, 0.8),
      _xf(_fleur, 50, 113, 0.6, rot: math.pi),
    ]) {
      canvas.drawPath(f, fill());
      canvas.drawPath(f, crownEdge..strokeWidth = 0.35);
    }

    if (sparkle) {
      final p = Paint()..color = Colors.white;
      canvas.drawPath(_spark(const Offset(94, 24), 4.5), p);
      canvas.drawPath(_spark(const Offset(8, 66), 3), p);
      canvas.drawPath(_spark(const Offset(84, 92), 2.6), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CrestPainter old) =>
      old.color != color || old.tier != tier || old.sparkle != sparkle;
}

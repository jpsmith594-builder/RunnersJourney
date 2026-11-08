import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../races/race.dart';
import 'runner_stats.dart';
import '../../core/units.dart';

class _Palette {
  final Color top;
  final Color bottom;
  final Color ink;
  final Color accent;
  final String label;
  const _Palette(this.top, this.bottom, this.ink, this.accent, this.label);
}

_Palette _paletteFor(CardTier t) {
  switch (t) {
    case CardTier.novice:
      return const _Palette(Color(0xFFE6AE7C), Color(0xFF8A5A2B),
          Color(0xFF3B2410), Color(0xFF5A3A1B), 'NOVICE');
    case CardTier.rookie:
      return const _Palette(Color(0xFFF2B08E), Color(0xFFB35A36),
          Color(0xFF3F1C0D), Color(0xFF7A3A1D), 'ROOKIE');
    case CardTier.club:
      return const _Palette(Color(0xFFF4F6F8), Color(0xFF9AA5B1),
          Color(0xFF22303C), Color(0xFF55616E), 'CLUB RUNNER');
    case CardTier.competitor:
      return const _Palette(Color(0xFFFCE58F), Color(0xFFC9962B),
          Color(0xFF3A2A05), Color(0xFF8A650F), 'COMPETITOR');
    case CardTier.veteran:
      return const _Palette(Color(0xFFD9F3F1), Color(0xFF4F9C9C),
          Color(0xFF0E3030), Color(0xFF1F6B6B), 'VETERAN');
    case CardTier.master:
      return const _Palette(Color(0xFF4D7CE0), Color(0xFF0A2A6B),
          Colors.white, Color(0xFF7FE3FF), 'MASTER');
    case CardTier.elite:
      return const _Palette(Color(0xFF2A2F6B), Color(0xFF6A3FD0),
          Colors.white, Color(0xFFFFD54F), 'ELITE');
  }
}

Path _shield(Size s) {
  final w = s.width, h = s.height, r = w * 0.09;
  return Path()
    ..moveTo(0, r)
    ..quadraticBezierTo(0, 0, r, 0)
    ..lineTo(w - r, 0)
    ..quadraticBezierTo(w, 0, w, r)
    ..lineTo(w, h * 0.80)
    ..quadraticBezierTo(w, h * 0.93, w / 2, h)
    ..quadraticBezierTo(0, h * 0.93, 0, h * 0.80)
    ..close();
}

class _ShieldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _shield(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Soft glow under the card.
class _ShieldGlow extends CustomPainter {
  final Color color;
  const _ShieldGlow(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(_shield(size), color, 14, true);
  }

  @override
  bool shouldRepaint(covariant _ShieldGlow old) => old.color != color;
}

/// Metallic double frame: a thick gradient rim, a thin bright line inside it
/// and a dark outer edge, with gems at the corners.
class _ShieldFrame extends CustomPainter {
  final _Palette p;
  final double unit;
  const _ShieldFrame(this.p, this.unit);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = _shield(size);

    // Rim
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * unit
        ..shader = SweepGradient(
          center: Alignment.center,
          colors: [
            p.top,
            p.accent,
            Colors.white,
            p.bottom,
            p.accent,
            p.top,
          ],
          stops: const [0.0, 0.2, 0.38, 0.6, 0.82, 1.0],
        ).createShader(rect),
    );
    // Dark outer edge
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * unit
        ..color = p.ink.withValues(alpha: 0.75),
    );
    // Bright inner line, set in from the edge
    final inset = 9 * unit;
    final inner = _shield(Size(size.width - 2 * inset, size.height - 2 * inset))
        .shift(Offset(inset, inset));
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * unit
        ..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * unit
        ..color = p.ink.withValues(alpha: 0.35),
    );

    // Gems at the top corners and the bottom point
    final r = size.width * 0.09;
    for (final c in [
      Offset(r * 0.55, r * 0.55),
      Offset(size.width - r * 0.55, r * 0.55),
      Offset(size.width / 2, size.height - 4 * unit),
    ]) {
      _gem(canvas, c, 5.5 * unit);
    }
  }

  void _gem(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r + 1.5 * unit, Paint()..color = p.ink.withValues(alpha: 0.8));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Colors.white, p.accent, p.ink],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant _ShieldFrame old) =>
      old.p != p || old.unit != unit;
}

/// Tiny four-point sparkles scattered over the card.
class _Sparkles extends CustomPainter {
  final Color color;
  const _Sparkles(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const spots = [
      [0.12, 0.30, 7.0],
      [0.45, 0.10, 5.0],
      [0.90, 0.40, 8.0],
      [0.78, 0.62, 5.0],
      [0.20, 0.72, 6.0],
      [0.55, 0.50, 4.0],
    ];
    final paint = Paint()..color = color;
    for (final s in spots) {
      final c = Offset(size.width * s[0], size.height * s[1]);
      final r = s[2] * size.width / 300;
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Sparkles old) => old.color != color;
}

class _Stripes extends CustomPainter {
  const _Stripes();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    for (var i = 0; i < 4; i++) {
      final x = size.width * (i * 0.34 - 0.15);
      final band = size.width * 0.16;
      final lean = size.height * 0.45;
      canvas.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(x + band, 0)
          ..lineTo(x + band - lean, size.height)
          ..lineTo(x - lean, size.height)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Stripes old) => false;
}

/// A football-style trading card for a runner: rating, photo, name and the
/// numbers from their races.
class RunnerCard extends StatelessWidget {
  final String name;
  final String? club;
  final String? homeTown;
  final String? favouriteDistance;
  final String? avatarUrl;
  final String? genderShort; // 'M', 'F', 'NB'
  final int? age;
  final RunnerStats stats;

  const RunnerCard({
    super.key,
    required this.name,
    required this.stats,
    this.club,
    this.homeTown,
    this.favouriteDistance,
    this.avatarUrl,
    this.genderShort,
    this.age,
  });

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'R';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = _paletteFor(stats.tier);
    return AspectRatio(
      aspectRatio: 0.70,
      child: LayoutBuilder(builder: (context, box) {
        final u = box.maxWidth / 300; // design units: card is 300 wide
        final subtitle = [
          if (club != null && club!.trim().isNotEmpty) club!.trim(),
          if (homeTown != null && homeTown!.trim().isNotEmpty) homeTown!.trim(),
        ].join('  •  ');
        final km = NumberFormat.decimalPattern()
            .format(toUnit(stats.totalKm).round());

        TextStyle ink(double size, {FontWeight w = FontWeight.w700}) =>
            TextStyle(
                color: p.ink, fontSize: size * u, fontWeight: w, height: 1.0);

        return CustomPaint(
          painter: _ShieldGlow(p.accent),
          foregroundPainter: _ShieldFrame(p, u),
          child: ClipPath(
            clipper: _ShieldClipper(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [p.top, p.bottom],
                ),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(child: CustomPaint(painter: _Stripes())),
                  Positioned.fill(
                      child: CustomPaint(
                          painter: _Sparkles(
                              Colors.white.withValues(alpha: 0.55)))),
                  // Glossy sheen
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.28),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.30, 0.45, 0.60],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Rating, distance, flag
                  Positioned(
                    left: 24 * u,
                    top: 34 * u,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${stats.rating}', style: ink(50, w: FontWeight.w900)),
                        SizedBox(height: 4 * u),
                        Text(favouriteDistance ?? 'RUN', style: ink(18)),
                        SizedBox(height: 8 * u),
                        Container(width: 30 * u, height: 2 * u, color: p.accent),
                        SizedBox(height: 8 * u),
                        Text('\u{1F1FF}\u{1F1E6}',
                            style: TextStyle(fontSize: 26 * u, height: 1.0)),
                        if (age != null || genderShort != null) ...[
                          SizedBox(height: 8 * u),
                          Text(
                              [
                                if (genderShort != null) genderShort!,
                                if (age != null) '$age',
                              ].join(' \u00B7 '),
                              style: ink(12)),
                        ],
                        SizedBox(height: 8 * u),
                        Text(p.label,
                            style: ink(10, w: FontWeight.w800)
                                .copyWith(letterSpacing: 1.5 * u)),
                      ],
                    ),
                  ),
                  // Photo
                  Positioned(
                    right: 22 * u,
                    top: 28 * u,
                    width: 172 * u,
                    height: 172 * u,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: p.accent, width: 3 * u),
                        color: p.accent.withValues(alpha: 0.25),
                      ),
                      child: ClipOval(
                        child: avatarUrl == null
                            ? _InitialsFace(_initials, p.ink, u)
                            : Image.network(
                                avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _InitialsFace(_initials, p.ink, u),
                              ),
                      ),
                    ),
                  ),
                  // Name
                  Positioned(
                    left: 16 * u,
                    right: 16 * u,
                    top: 212 * u,
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(name.toUpperCase(),
                              maxLines: 1,
                              style: ink(26, w: FontWeight.w900)
                                  .copyWith(letterSpacing: 1 * u)),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          SizedBox(height: 5 * u),
                          Text(subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ink(11, w: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                  // Headline numbers
                  Positioned(
                    left: 24 * u,
                    right: 24 * u,
                    top: 266 * u,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _Stat('${stats.completed}', 'RACES', p.ink, u),
                        _Stat(km, unitLabel().toUpperCase(), p.ink, u),
                        _Stat('${stats.towns}', 'TOWNS', p.ink, u),
                      ],
                    ),
                  ),
                  // Personal bests
                  Positioned(
                    left: 30 * u,
                    right: 30 * u,
                    top: 328 * u,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Pb('5K', stats.pb5k, p.ink, u),
                        _Pb('10K', stats.pb10k, p.ink, u),
                        _Pb('21K', stats.pb21k, p.ink, u),
                        _Pb('42K', stats.pb42k, p.ink, u),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _InitialsFace extends StatelessWidget {
  final String initials;
  final Color color;
  final double u;
  const _InitialsFace(this.initials, this.color, this.u);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 64 * u,
            fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final double u;
  const _Stat(this.value, this.label, this.color, this.u);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 24 * u,
                fontWeight: FontWeight.w900,
                height: 1.0)),
        SizedBox(height: 3 * u),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 9 * u,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2 * u)),
      ],
    );
  }
}

class _Pb extends StatelessWidget {
  final String label;
  final int? seconds;
  final Color color;
  final double u;
  const _Pb(this.label, this.seconds, this.color, this.u);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10 * u,
                fontWeight: FontWeight.w800,
                letterSpacing: 1 * u)),
        SizedBox(height: 2 * u),
        Text(seconds == null ? '--' : formatDuration(seconds),
            style: TextStyle(
                color: color,
                fontSize: 12 * u,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

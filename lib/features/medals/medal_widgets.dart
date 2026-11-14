import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'medal.dart';

/// Colours of the wall: deep purple, darker at the top.
const wallTop = Color(0xFF1A0A30);
const wallBottom = Color(0xFF2B1250);
const wallGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [wallTop, wallBottom],
  ),
);

const _neon = LinearGradient(
  colors: [Color(0xFFFF5FD2), Color(0xFFFFB02E), Color(0xFF2FD8FF)],
);

/// The wall header: bold italic neon-outlined letters over two curved LED track lanes.
class LedTitle extends StatelessWidget {
  final String text;
  const LedTitle(this.text, {super.key});

  Widget _letters({required bool glow}) {
    const base = TextStyle(
      fontSize: 46,
      height: 1.1,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: 2,
    );
    if (glow) {
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => _neon.createShader(r),
          child: Text(text, style: base.copyWith(color: Colors.white)),
        ),
      );
    }
    // Dark letter faces with a neon outline, as if the glow comes from behind.
    return Stack(
      children: [
        Text(
          text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..shader = _neon.createShader(const Rect.fromLTWH(0, 0, 300, 50)),
          ),
        ),
        Text(text, style: base.copyWith(color: const Color(0xFF2A2430))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: text,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 118,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              const Positioned.fill(child: CustomPaint(painter: _LanesPainter())),
              Positioned(
                top: 0,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [_letters(glow: true), _letters(glow: false)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanesPainter extends CustomPainter {
  const _LanesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    for (final dy in [74.0, 98.0]) {
      final path = Path()
        ..moveTo(0, dy)
        ..quadraticBezierTo(size.width / 2, dy - 56, size.width, dy);
      final glow = Paint()
        ..shader = _neon.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      final line = Paint()
        ..shader = _neon.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glow);
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// A titanium hanger bar lit from behind by an LED strip.
class HangerBar extends StatelessWidget {
  const HangerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3E8EE), Color(0xFF9AA4B0), Color(0xFF5C6672)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x887FD9FF), blurRadius: 18, spreadRadius: 1),
          BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
    );
  }
}

/// A medal: the picture inside a metal ring, hanging from a ribbon.
class MedalView extends StatelessWidget {
  final ImageProvider image;
  final MedalMetal metal;
  final MedalRibbon ribbon;

  /// When set (the medal's race has a known distance) this replaces the
  /// ribbon colour, so ribbons use the same colours as the map pins.
  final Color? ribbonColour;
  final double size;

  const MedalView({
    super.key,
    required this.image,
    required this.metal,
    required this.ribbon,
    this.ribbonColour,
    this.size = 92,
  });

  static const _ribbonDrop = 32.0;

  /// Total height of the ribbon and medal together.
  static double heightFor(double size) => size + _ribbonDrop;

  @override
  Widget build(BuildContext context) {
    const ribbonWidth = 30.0;
    return SizedBox(
      width: size,
      height: heightFor(size),
      child: Stack(
        children: [
          Positioned(
            left: (size - ribbonWidth) / 2,
            top: 0,
            width: ribbonWidth,
            height: _ribbonDrop + 14,
            child: Container(
              color: ribbonColour ?? ribbon.color,
              alignment: Alignment.center,
              child: Container(
                  width: 8,
                  color: ribbonColour != null ? Colors.white : ribbon.stripe,
                ),
            ),
          ),
          Positioned(
            left: 0,
            top: _ribbonDrop,
            width: size,
            height: size,
            child: Container(
              padding: EdgeInsets.all(size * 0.06),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: metal.rim,
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 10,
                      offset: Offset(0, 4)),
                ],
              ),
              child: ClipOval(
                child: Image(
                  image: image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0x33FFFFFF)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

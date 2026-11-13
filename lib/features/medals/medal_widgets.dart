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

/// Bold italic LED letters that glow against the wall.
class LedTitle extends StatelessWidget {
  final String text;
  const LedTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
          letterSpacing: 3,
          color: Color(0xFFEFFDFF),
          shadows: [
            Shadow(color: Color(0xFFBFF6FF), blurRadius: 3),
            Shadow(color: Color(0xFF2FD8FF), blurRadius: 14),
            Shadow(color: Color(0xAA2FD8FF), blurRadius: 34),
          ],
        ),
      ),
    );
  }
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
  final double size;

  const MedalView({
    super.key,
    required this.image,
    required this.metal,
    required this.ribbon,
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
              color: ribbon.color,
              alignment: Alignment.center,
              child: Container(width: 8, color: ribbon.stripe),
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

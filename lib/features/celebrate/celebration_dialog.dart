import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'celebrations.dart';

/// Shows the celebrations one after another, each with confetti.
Future<void> showCelebrations(
    BuildContext context, List<Celebration> items) async {
  if (items.isEmpty) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => CelebrationPopup(items: items),
  );
}

class CelebrationPopup extends StatefulWidget {
  final List<Celebration> items;
  const CelebrationPopup({super.key, required this.items});

  @override
  State<CelebrationPopup> createState() => _CelebrationPopupState();
}

class _CelebrationPopupState extends State<CelebrationPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800))
    ..forward();
  int _i = 0;

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _next() {
    if (_i >= widget.items.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _i++);
    _confetti.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.items[_i];
    final last = _i == widget.items.length - 1;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, __) => CustomPaint(
                    painter: ConfettiPainter(_confetti.value, seed: _i)),
              ),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    key: ValueKey(_i),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                          color: c.color.withValues(alpha: 0.18),
                          shape: BoxShape.circle),
                      child: Icon(c.icon, size: 64, color: c.color),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(c.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(c.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, height: 1.35)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: _next,
                        child: Text(last ? 'Nice!' : 'Next')),
                  ),
                  if (widget.items.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('${_i + 1} of ${widget.items.length}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Falling coloured pieces; [t] runs 0 to 1.
class ConfettiPainter extends CustomPainter {
  final double t;
  final int seed;
  ConfettiPainter(this.t, {this.seed = 0});

  static const _colors = [
    Color(0xFFF2A900),
    Color(0xFF1FA85A),
    Color(0xFF2F7DE1),
    Color(0xFFE5484D),
    Color(0xFF7B3FE4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed + 7);
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      final x0 = rnd.nextDouble() * size.width;
      final delay = rnd.nextDouble() * 0.35;
      final speed = 0.7 + rnd.nextDouble() * 0.6;
      final sway = (rnd.nextDouble() - 0.5) * 80;
      final spin = rnd.nextDouble() * 6;
      final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -20 + local * speed * (size.height + 40);
      final x = x0 + math.sin(local * 6 + spin) * sway * 0.3;
      paint.color = _colors[i % _colors.length]
          .withValues(alpha: (1 - local * 0.6).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * spin * 3);
      canvas.drawRect(const Rect.fromLTWH(-4, -2, 8, 4), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => old.t != t || old.seed != seed;
}

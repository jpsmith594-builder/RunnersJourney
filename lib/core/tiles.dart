import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Building blocks for the app's card-and-tile look: soft grey canvas, big
/// rounded white cards, round icon bubbles, large numbers and progress rings.

/// A big rounded card with a very soft shadow.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = cs.brightness == Brightness.dark;
    final r = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? cs.surface,
        borderRadius: r,
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 18,
                    offset: Offset(0, 6)),
              ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A round, softly tinted background behind an icon.
class IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBubble(
      {super.key, required this.icon, required this.color, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// Heading above a group of cards, with an optional action on the right.
class SectionTitle extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.text, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary)),
            ),
        ],
      ),
    );
  }
}

/// A square-ish tile: icon bubble, big number, small label.
class StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? unit;
  final String? note;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.unit,
    this.note,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7);
    return SoftCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconBubble(icon: icon, color: color, size: 34),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: muted)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w800, height: 1)),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(unit!,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: muted)),
              ],
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(note!, style: TextStyle(fontSize: 12, color: muted)),
          ],
        ],
      ),
    );
  }
}

/// A circular progress ring with a child in the middle.
class RingProgress extends StatelessWidget {
  final double value; // 0..1
  final double size;
  final double stroke;
  final Color color;
  final Widget? child;

  const RingProgress({
    super.key,
    required this.value,
    this.size = 84,
    this.stroke = 10,
    required this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value.clamp(0, 1).toDouble(), stroke, color,
            color.withValues(alpha: 0.15)),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double stroke;
  final Color color;
  final Color track;
  _RingPainter(this.value, this.stroke, this.color, this.track);

  @override
  void paint(Canvas canvas, Size s) {
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s.width - stroke,
        s.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (value > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/tiles.dart';
import '../races/race.dart';
import '../races/race_list_screen.dart' show medalColor;
import '../races/race_store.dart';
import '../../core/units.dart';

/// Numbers behind the four charts. Only completed races count.
class ChartStats {
  final Map<int, int> racesPerYear;
  final Map<int, double> kmPerYear;

  /// Average pace per year in seconds per km (total time / total distance).
  final Map<int, double> paceSecPerKm;

  /// Medals collected at races: 'gold', 'silver', 'bronze'.
  final Map<String, int> medals;

  const ChartStats(
      this.racesPerYear, this.kmPerYear, this.paceSecPerKm, this.medals);

  factory ChartStats.from(List<Race> races) {
    final count = <int, int>{};
    final km = <int, double>{};
    final secs = <int, double>{};
    final paceKm = <int, double>{};
    for (final r in races) {
      if (r.status != RaceStatus.completed) continue;
      final y = r.date.year;
      count[y] = (count[y] ?? 0) + 1;
      km[y] = (km[y] ?? 0) + (r.distanceKm ?? 0);
      final d = r.distanceKm, t = r.finishTimeSeconds;
      if (d != null && t != null && d > 0 && t > 0) {
        paceKm[y] = (paceKm[y] ?? 0) + d;
        secs[y] = (secs[y] ?? 0) + t;
      }
    }
    final pace = {
      for (final y in secs.keys) y: secs[y]! / paceKm[y]!,
    };
    final medals = {'gold': 0, 'silver': 0, 'bronze': 0};
    for (final r in races) {
      final m = r.medal;
      if (r.status == RaceStatus.completed && m != null && medals.containsKey(m)) {
        medals[m] = medals[m]! + 1;
      }
    }
    return ChartStats(count, km, pace, medals);
  }

  /// The most recent [n] years of a map, oldest first.
  static List<MapEntry<int, T>> lastYears<T>(Map<int, T> m, [int n = 8]) {
    final e = m.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return e.length > n ? e.sublist(e.length - n) : e;
  }
}

String paceLabel(double secPerKm) {
  final s = secPerKm.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

class ChartsScreen extends StatelessWidget {
  final RaceStore store;
  const ChartsScreen({super.key, required this.store});

  Widget _card(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required bool empty,
      String emptyText = 'Finish a race to see this chart.',
      required Widget chart}) {
    final muted =
        Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7);
    return SoftCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(icon: icon, color: color, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (empty)
            SizedBox(
              height: 90,
              child: Center(
                child: Text(emptyText,
                    style: TextStyle(color: muted)),
              ),
            )
          else
            chart,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme.bodyMedium?.color ??
        (dark ? Colors.white : Colors.black87);
    final green = AppTheme.runGreen(Theme.of(context).brightness);
    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final s = ChartStats.from(store.races);
          final perYear = ChartStats.lastYears(s.racesPerYear);
          final kmYear = ChartStats.lastYears(s.kmPerYear);
          final paceYear = ChartStats.lastYears(s.paceSecPerKm);
          final medals = [
            for (final m in const ['gold', 'silver', 'bronze'])
              if ((s.medals[m] ?? 0) > 0) (m, s.medals[m]!),
          ];
          return ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 28),
            children: [
              _card(
                context,
                title: 'Races per year',
                subtitle: 'Finished races',
                icon: Icons.bar_chart,
                color: AppTheme.purpleMid,
                empty: perYear.isEmpty,
                chart: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _BarPainter(
                      [for (final e in perYear) ('${e.key}', e.value.toDouble())],
                      dark ? const Color(0xFFD9B8FF) : AppTheme.purpleMid,
                      text,
                      (v) => v.round().toString(),
                    ),
                  ),
                ),
              ),
              _card(
                context,
                title: 'Medals collected',
                subtitle: 'Gold, silver and bronze from your races',
                icon: Icons.emoji_events_outlined,
                color: const Color(0xFFFFB400),
                empty: medals.isEmpty,
                emptyText: 'Add a medal to a finished race to see this chart.',
                chart: _Donut(
                  slices: [
                    for (final (m, n) in medals)
                      (
                        '${m[0].toUpperCase()}${m.substring(1)}',
                        n.toDouble(),
                        medalColor(m)
                      ),
                  ],
                  centreLabel: 'medals',
                  text: text,
                ),
              ),
              _card(
                context,
                title: 'Pace by year',
                subtitle: 'Average min/${unitLabel()}, lower is faster',
                icon: Icons.show_chart,
                color: green,
                empty: paceYear.isEmpty,
                chart: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _LinePainter(
                      [for (final e in paceYear) ('${e.key}', paceInUnit(e.value))],
                      green,
                      text,
                    ),
                  ),
                ),
              ),
              _card(
                context,
                title: 'Distance per year',
                subtitle: 'Finished races, in ${unitWord()}',
                icon: Icons.stacked_bar_chart,
                color: const Color(0xFFFF9F0A),
                empty: kmYear.isEmpty,
                chart: SizedBox(
                  height: kmYear.length * 34.0 + 6,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _HBarPainter(
                      [for (final e in kmYear) ('${e.key}', toUnit(e.value))],
                      const Color(0xFFFF9F0A),
                      text,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

void _label(Canvas canvas, String text, Offset at, Color color,
    {double size = 11,
    FontWeight weight = FontWeight.w600,
    TextAlign align = TextAlign.center,
    bool centreY = false}) {
  final tp = TextPainter(
    text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight)),
    textDirection: TextDirection.ltr,
  )..layout();
  var dx = at.dx;
  if (align == TextAlign.center) dx -= tp.width / 2;
  if (align == TextAlign.right) dx -= tp.width;
  tp.paint(canvas, Offset(dx, centreY ? at.dy - tp.height / 2 : at.dy));
}

/// Vertical bars with the value above each one.
class _BarPainter extends CustomPainter {
  final List<(String, double)> data;
  final Color color;
  final Color text;
  final String Function(double) format;
  _BarPainter(this.data, this.color, this.text, this.format);

  @override
  void paint(Canvas canvas, Size s) {
    const top = 20.0, bottom = 22.0;
    final maxV = data.map((e) => e.$2).fold<double>(0, math.max);
    if (maxV <= 0) return;
    final h = s.height - top - bottom;
    final slot = s.width / data.length;
    final bw = math.min(slot * 0.55, 46.0);
    for (var i = 0; i < data.length; i++) {
      final (label, v) = data[i];
      final cx = slot * i + slot / 2;
      final bh = math.max(4.0, h * v / maxV);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - bw / 2, top + h - bh, bw, bh),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withValues(alpha: 0.45)],
          ).createShader(rect.outerRect),
      );
      _label(canvas, format(v), Offset(cx, top + h - bh - 16), text,
          weight: FontWeight.w800);
      _label(canvas, label, Offset(cx, s.height - 16), text.withValues(alpha: 0.65));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.data != data || old.color != color || old.text != text;
}

/// Horizontal bars, one row per year.
class _HBarPainter extends CustomPainter {
  final List<(String, double)> data;
  final Color color;
  final Color text;
  _HBarPainter(this.data, this.color, this.text);

  @override
  void paint(Canvas canvas, Size s) {
    final maxV = data.map((e) => e.$2).fold<double>(0, math.max);
    if (maxV <= 0) return;
    const labelW = 40.0, valueW = 70.0, row = 34.0, barH = 18.0;
    final barMax = s.width - labelW - valueW;
    for (var i = 0; i < data.length; i++) {
      final (label, v) = data[i];
      final cy = row * i + row / 2 + 3;
      _label(canvas, label, Offset(0, cy), text.withValues(alpha: 0.65),
          align: TextAlign.left, centreY: true);
      final w = math.max(6.0, barMax * v / maxV);
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(labelW, cy - barH / 2, w, barH),
          const Radius.circular(9));
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [color.withValues(alpha: 0.5), color],
          ).createShader(rect.outerRect),
      );
      _label(canvas, '${formatNumber(v)} ${unitLabel()}',
          Offset(labelW + w + 8, cy), text,
          align: TextAlign.left, weight: FontWeight.w800, centreY: true);
    }
  }

  @override
  bool shouldRepaint(covariant _HBarPainter old) =>
      old.data != data || old.color != color || old.text != text;
}

/// Line with dots; the vertical axis shows pace as m:ss.
class _LinePainter extends CustomPainter {
  final List<(String, double)> data;
  final Color color;
  final Color text;
  _LinePainter(this.data, this.color, this.text);

  @override
  void paint(Canvas canvas, Size s) {
    const left = 44.0, right = 14.0, top = 16.0, bottom = 24.0;
    final vals = data.map((e) => e.$2).toList();
    var lo = vals.reduce(math.min), hi = vals.reduce(math.max);
    if (hi - lo < 20) {
      final mid = (hi + lo) / 2;
      lo = mid - 15;
      hi = mid + 15;
    } else {
      final pad = (hi - lo) * 0.15;
      lo -= pad;
      hi += pad;
    }
    final w = s.width - left - right;
    final h = s.height - top - bottom;
    double xOf(int i) =>
        data.length == 1 ? left + w / 2 : left + w * i / (data.length - 1);
    double yOf(double v) => top + h * (v - lo) / (hi - lo);

    final grid = Paint()
      ..color = text.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var g = 0; g < 3; g++) {
      final v = lo + (hi - lo) * g / 2;
      final y = yOf(v);
      canvas.drawLine(Offset(left, y), Offset(s.width - right, y), grid);
      _label(canvas, paceLabel(v), Offset(left - 8, y), text.withValues(alpha: 0.65),
          align: TextAlign.right, centreY: true, size: 10);
    }

    final pts = [for (var i = 0; i < data.length; i++) Offset(xOf(i), yOf(vals[i]))];
    if (pts.length > 1) {
      final area = Path()..moveTo(pts.first.dx, top + h);
      for (final p in pts) {
        area.lineTo(p.dx, p.dy);
      }
      area
        ..lineTo(pts.last.dx, top + h)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
          ).createShader(Rect.fromLTWH(left, top, w, h)),
      );
      final line = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        line.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
    }
    for (var i = 0; i < pts.length; i++) {
      canvas.drawCircle(pts[i], 6, Paint()..color = color.withValues(alpha: 0.25));
      canvas.drawCircle(pts[i], 4, Paint()..color = color);
      _label(canvas, paceLabel(vals[i]), pts[i].translate(0, -20), text,
          weight: FontWeight.w800, size: 10);
      _label(canvas, data[i].$1, Offset(pts[i].dx, s.height - 16),
          text.withValues(alpha: 0.65));
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.data != data || old.color != color || old.text != text;
}

/// Donut chart with a legend.
class _Donut extends StatelessWidget {
  final List<(String, double, Color)> slices;
  final Color text;
  final String centreLabel;
  const _Donut(
      {required this.slices, required this.text, required this.centreLabel});

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (a, e) => a + e.$2);
    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: CustomPaint(
            painter: _DonutPainter(slices, text),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${total.round()}',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800)),
                  Text(centreLabel,
                      style: TextStyle(
                          fontSize: 12, color: text.withValues(alpha: 0.65))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (name, n, c) in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration:
                            BoxDecoration(color: c, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13))),
                      Text('${n.round()}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<(String, double, Color)> slices;
  final Color text;
  _DonutPainter(this.slices, this.text);

  @override
  void paint(Canvas canvas, Size s) {
    final total = slices.fold<double>(0, (a, e) => a + e.$2);
    if (total <= 0) return;
    const stroke = 24.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s.width - stroke, s.height - stroke);
    var start = -math.pi / 2;
    const gap = 0.04;
    for (final (_, v, c) in slices) {
      final sweep = math.pi * 2 * v / total;
      canvas.drawArc(
        rect,
        start + (slices.length > 1 ? gap / 2 : 0),
        math.max(0.01, sweep - (slices.length > 1 ? gap : 0)),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = c,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.slices != slices || old.text != text;
}

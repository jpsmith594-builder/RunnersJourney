import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'map_overlay.dart';

/// Pixels drawn per point. The map engine scales the picture back down.
const double kPinImageScale = 3;

/// Draws a marker as a PNG, matching the pins the journey screen used to
/// draw as Flutter widgets.
Future<Uint8List> renderPinImage(NativePin p) async {
  const k = kPinImageScale;
  const pad = 4.0; // room for the shadow at the sides and top
  final w = p.w, h = p.h;
  final width = p.shape == PinShape.teardrop ? w + pad * 2 : w;
  final height = p.shape == PinShape.teardrop ? h + pad : h;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.scale(k);
  switch (p.shape) {
    case PinShape.teardrop:
      _teardrop(canvas, p, pad);
    case PinShape.dot:
      final c = Offset(w / 2, h / 2);
      canvas.drawCircle(c, w / 2, Paint()..color = Colors.white);
      canvas.drawCircle(c, w / 2 - 2, Paint()..color = p.fill);
    case PinShape.pill:
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h), const Radius.circular(10));
      canvas.drawRRect(r, Paint()..color = p.fill);
      _centredText(canvas, p.text, p.ink, p.fontSize, Offset(w / 2, h / 2));
  }
  final img = await rec
      .endRecording()
      .toImage((width * k).ceil(), (height * k).ceil());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void _teardrop(Canvas canvas, NativePin p, double pad) {
  final w = p.w, h = p.h;
  final radius = w * 0.42;
  final cx = w / 2 + pad;
  final top = pad;
  final path = Path()
    ..addOval(Rect.fromCircle(center: Offset(cx, top + radius), radius: radius))
    ..moveTo(cx - radius * 0.6, top + radius + radius * 0.8)
    ..lineTo(cx, top + h)
    ..lineTo(cx + radius * 0.6, top + radius + radius * 0.8)
    ..close();
  canvas.drawShadow(path, Colors.black, 3, true);
  canvas.drawPath(path, Paint()..color = p.fill);
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = p.ring == null ? 2 : 3
      ..color = p.ring ?? Colors.white,
  );
  final centre = Offset(cx, top + radius);
  final icon = p.icon;
  if (icon != null) {
    _centredText(
      canvas,
      String.fromCharCode(icon.codePoint),
      p.ink,
      18,
      centre,
      family: icon.fontFamily,
      package: icon.fontPackage,
    );
  } else if (p.text.isNotEmpty) {
    _centredText(canvas, p.text, p.ink, p.fontSize, centre);
  }
}

void _centredText(
  Canvas canvas,
  String text,
  Color colour,
  double size,
  Offset centre, {
  String? family,
  String? package,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: colour,
        fontSize: size,
        fontWeight: FontWeight.w800,
        fontFamily: family,
        package: package,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
}

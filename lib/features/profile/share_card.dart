import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

/// Puts a runner card on a dark "stage" with the app name underneath. This is
/// what gets turned into the picture that is shared.
class CardStage extends StatelessWidget {
  final GlobalKey boundaryKey;
  final Widget child;
  const CardStage({super.key, required this.boundaryKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2A4E), Color(0xFF0B1220)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 12),
            const Text(
              'RUNNER\'S JOURNEY',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the card inside [boundaryKey] as a PNG and opens the phone's share
/// sheet (WhatsApp, Instagram, Messages, Save to gallery and so on).
Future<void> shareRunnerCard(
  BuildContext context,
  GlobalKey boundaryKey, {
  required String message,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw 'The card is not on screen yet';
    }
    // Make sure the latest frame (and the photo) has been painted.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw 'Could not draw the card';
    final bytes = data.buffer.asUint8List();
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'image/png', name: 'runner_card.png')],
      fileNameOverrides: const ['runner_card.png'],
      text: message,
    );
  } catch (e) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Could not share the card: $e')));
  }
}

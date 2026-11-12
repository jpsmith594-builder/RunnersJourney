import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/brand.dart';
import '../../core/errors.dart';
import '../../core/invite.dart';

/// Puts a runner card on a tall 9:16 "story" stage with the app name. This is
/// what gets turned into the picture that is shared, so it fits Instagram and
/// Facebook Stories, WhatsApp Status and TikTok without cropping.
class CardStage extends StatelessWidget {
  final GlobalKey boundaryKey;
  final Widget child;
  const CardStage({super.key, required this.boundaryKey, required this.child});

  @override
  Widget build(BuildContext context) {
    const brand = TextStyle(
      color: Colors.white70,
      fontSize: 12,
      letterSpacing: 3,
      fontWeight: FontWeight.w800,
    );
    return RepaintBoundary(
      key: boundaryKey,
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6B1B9A), Color(0xFF37003C), Color(0xFF1A0020)],
              stops: [0.0, 0.65, 1.0],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, box) => FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: box.maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
              const Text('MY RUNNING JOURNAL', style: brand),
              const SizedBox(height: 18),
              child,
              const SizedBox(height: 18),
              const Text(brandMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  )),
              const SizedBox(height: 16),
              const InviteFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders the card inside [boundaryKey] as a PNG and opens the phone's share
/// sheet (Instagram, Facebook, WhatsApp, TikTok, Messages, Save to gallery...).
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
    // 1080 pixels wide, the size story apps expect (1080 x 1920).
    final image = await boundary.toImage(
        pixelRatio: 1080 / boundary.size.width);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw 'Could not draw the card';
    final bytes = data.buffer.asUint8List();
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'image/png', name: 'runner_card.png')],
      fileNameOverrides: const ['runner_card.png'],
      text: withInvite(message),
    );
  } catch (e) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(failMessage('Could not share the card', e))));
  }
}

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'medal_widgets.dart';

/// Lets the runner pinch and drag a photo of their medal into a circle.
/// Pops with an 800 px PNG of the circle (transparent outside it), or null.
class AdjustMedalScreen extends StatefulWidget {
  final Uint8List bytes;
  const AdjustMedalScreen({super.key, required this.bytes});

  @override
  State<AdjustMedalScreen> createState() => _AdjustMedalScreenState();
}

class _AdjustMedalScreenState extends State<AdjustMedalScreen> {
  static const _outputPixels = 800.0;
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<void> _done() async {
    setState(() => _busy = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final ratio = _outputPixels / boundary.size.width;
      final image = await boundary.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      if (data == null) throw StateError('no image data');
      Navigator.of(context).pop(data.buffer.asUint8List());
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not prepare the picture. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final side = (width - 48).clamp(200.0, 420.0).toDouble();
    return Scaffold(
      backgroundColor: wallTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Centre your medal'),
      ),
      body: Container(
        decoration: wallGradient,
        width: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              SizedBox(
                width: side,
                height: side,
                child: Stack(
                  children: [
                    RepaintBoundary(
                      key: _boundaryKey,
                      child: ClipOval(
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 6,
                          child: Image.memory(
                            widget.bytes,
                            width: side,
                            height: side,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Pinch and drag so the medal fills the circle. A plain '
                  'background and good light look best.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _done,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Use this picture'),
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

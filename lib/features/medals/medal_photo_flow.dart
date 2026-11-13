import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'adjust_medal_screen.dart';

/// Asks camera or gallery, then lets the runner fit the medal into a circle.
/// Returns the circle cut-out as PNG bytes, or null if they backed out.
Future<Uint8List?> pickAndAdjustMedalPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            subtitle: const Text('Use a plain surface and good light'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return null;
  Uint8List bytes;
  try {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    if (file == null) return null;
    bytes = await file.readAsBytes();
  } catch (_) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')));
    return null;
  }
  if (!context.mounted) return null;
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(builder: (_) => AdjustMedalScreen(bytes: bytes)),
  );
}

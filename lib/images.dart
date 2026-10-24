import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<String?> pickImageBase64(BuildContext context,
    {double max = 900, int quality = 60}) async {
  try {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: max,
      maxHeight: max,
      imageQuality: quality,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > 600000) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Image is too large. Pick a smaller one.')),
        );
      }
      return null;
    }
    return base64Encode(bytes);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Image error: $e')));
    }
    return null;
  }
}

Widget b64Image(String data, {BoxFit fit = BoxFit.cover, double? height}) {
  try {
    return Image.memory(
      base64Decode(data),
      fit: fit,
      height: height,
      width: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (c, e, s) => const SizedBox.shrink(),
    );
  } catch (e) {
    return const SizedBox.shrink();
  }
}

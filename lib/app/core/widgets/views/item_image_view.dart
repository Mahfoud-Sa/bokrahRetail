import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// Renders an item image from a `data:image/...;base64,...` URI, an HTTP/HTTPS
/// URL, or a local file path on disk, falling back to [fallback] when invalid.
class ItemImageView extends StatelessWidget {
  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const ItemImageView({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final defaultFallback =
        fallback ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );

    final raw = source?.trim() ?? '';
    if (raw.isEmpty) {
      return defaultFallback;
    }

    if (raw.startsWith('data:image')) {
      final commaIdx = raw.indexOf(',');
      if (commaIdx != -1) {
        try {
          final decoded = base64Decode(raw.substring(commaIdx + 1));
          return Image.memory(
            decoded,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => defaultFallback,
          );
        } catch (_) {
          return defaultFallback;
        }
      }
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return Image.network(
        raw,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => defaultFallback,
      );
    }

    final file = File(raw);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => defaultFallback,
      );
    }

    return defaultFallback;
  }
}

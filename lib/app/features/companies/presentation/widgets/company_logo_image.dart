import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bokrah_retail/app/config/theme.dart';
import 'package:flutter/material.dart';

/// Renders a company logo from in-memory bytes, base64 data URI, network URL,
/// or local file path, falling back to [fallback] when unavailable.
class CompanyLogoImage extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageUrl;
  final Widget? fallback;

  const CompanyLogoImage({
    super.key,
    this.imageBytes,
    this.imageUrl,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final defaultFallback =
        fallback ??
        const Center(
          child: Icon(Icons.business, color: AppTheme.secondaryText, size: 30),
        );

    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => defaultFallback,
      );
    }

    final raw = imageUrl?.trim() ?? '';
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
            fit: BoxFit.contain,
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
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => defaultFallback,
      );
    }

    final file = File(raw);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => defaultFallback,
      );
    }

    return defaultFallback;
  }
}

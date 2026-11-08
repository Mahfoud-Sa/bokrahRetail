
import 'package:flutter/material.dart';

class SystemFeature {
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;

  SystemFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
  });

  SystemFeature copyWith({
    IconData? icon,
    String? title,
    String? description,
    bool? enabled,
  }) {
    return SystemFeature(
      icon: icon ?? this.icon,
      title: title ?? this.title,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
    );
  }
}


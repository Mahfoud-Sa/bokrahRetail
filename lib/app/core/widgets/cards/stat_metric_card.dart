import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';

/// Style configuration for [StatMetricCard].
class StatMetricStyle {
  final Color color;
  final String? subtitle;

  const StatMetricStyle({
    this.color = AppTheme.actionBlue,
    this.subtitle,
  });
}

/// A clean, reusable metric card displaying a KPI statistic with an icon and optional styling.
/// Adheres strictly to the <= 3 constructor arguments rule:
/// 1. [title] (String)
/// 2. [value] (String)
/// 3. [icon] (IconData) or [style] (StatMetricStyle)
class StatMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final StatMetricStyle style;

  const StatMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.icon = Icons.analytics_outlined,
    this.style = const StatMetricStyle(),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: style.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: style.color,
                  ),
                ),
                if (style.subtitle != null && style.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    style.subtitle!,
                    style: const TextStyle(fontSize: 11, color: AppTheme.mutedText),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

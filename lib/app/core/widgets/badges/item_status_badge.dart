import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';

/// Returns the brand color associated with a given [ItemUsageStatus].
Color getItemStatusColor(ItemUsageStatus status) {
  return switch (status) {
    ItemUsageStatus.newItem => AppTheme.success,
    ItemUsageStatus.renew => AppTheme.warmOrange,
    ItemUsageStatus.used => Colors.blueGrey,
  };
}

/// Returns the icon associated with a given [ItemUsageStatus].
IconData getItemStatusIcon(ItemUsageStatus status) {
  return switch (status) {
    ItemUsageStatus.newItem => Icons.fiber_new_rounded,
    ItemUsageStatus.renew => Icons.autorenew_rounded,
    ItemUsageStatus.used => Icons.history_rounded,
  };
}

/// A shared badge widget to display item usage status (new, renew, used).
class ItemStatusBadge extends StatelessWidget {
  final ItemUsageStatus status;
  final bool showValue;

  const ItemStatusBadge({
    super.key,
    required this.status,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = getItemStatusColor(status);
    final icon = getItemStatusIcon(status);

    final text = showValue
        ? '${status.labelAr} (${status.value})'
        : status.labelAr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:bokrah_retail/app/core/widgets/badges/item_status_badge.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:flutter/material.dart';

/// ChoiceChip selector for [ItemUsageStatus].
class ItemUsageStatusSelector extends StatelessWidget {
  final ItemUsageStatus value;
  final ValueChanged<ItemUsageStatus> onChanged;

  const ItemUsageStatusSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'حالة الاستخدام (Usage Status) *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ItemUsageStatus.values.map((status) {
            final isSelected = value == status;
            final color = getItemStatusColor(status);
            final icon = getItemStatusIcon(status);

            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${status.labelAr} (${status.value})',
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              selectedColor: color,
              backgroundColor: Colors.grey[100],
              onSelected: (selected) {
                if (selected) {
                  onChanged(status);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

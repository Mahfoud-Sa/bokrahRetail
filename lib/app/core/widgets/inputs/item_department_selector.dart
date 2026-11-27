import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/widgets/inputs/app_form_text_field.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:flutter/material.dart';

/// Department dropdown selector with selected-department summary badge and quick-add action.
class ItemDepartmentSelector extends StatelessWidget {
  final List<DepartmentEntity> departments;
  final int? selectedDepartmentId;
  final ValueChanged<int?> onChanged;
  final VoidCallback onQuickAdd;

  const ItemDepartmentSelector({
    super.key,
    required this.departments,
    required this.selectedDepartmentId,
    required this.onChanged,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final validDepartmentId =
        departments.any((d) => d.id == selectedDepartmentId)
        ? selectedDepartmentId
        : null;
    final selectedDept = validDepartmentId != null
        ? departments.firstWhere((d) => d.id == validDepartmentId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.domain_outlined,
                  size: 18,
                  color: AppTheme.actionBlue,
                ),
                SizedBox(width: 6),
                Text(
                  'القسم التابع له العنصر (Department)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: onQuickAdd,
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text(
                'إضافة قسم سريع',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'العنصر يتبع لقسم واحد فقط ضمن النظام (علاقة 1 إلى متعدد)',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (selectedDept != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.actionBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.actionBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  color: AppTheme.actionBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedDept.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepCobalt,
                          fontSize: 13,
                        ),
                      ),
                      if (selectedDept.code != null)
                        Text(
                          'كود القسم: ${selectedDept.code}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  tooltip: 'إلغاء تحديد القسم',
                  onPressed: () => onChanged(null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        DropdownButtonFormField<int?>(
          key: ValueKey(validDepartmentId),
          isExpanded: true,
          initialValue: validDepartmentId,
          decoration: buildAppInputDecoration(
            label: 'اختر قسم العنصر من القائمة',
            icon: Icons.domain_outlined,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'بدون قسم (عام)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ...departments.map((d) {
              return DropdownMenuItem<int?>(
                value: d.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.apartment_outlined,
                      size: 16,
                      color: AppTheme.actionBlue,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        d.code != null ? '${d.name} (${d.code})' : d.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.deepCobalt,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/widgets/inputs/app_form_text_field.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:flutter/material.dart';

/// Category tree selector with browse-tree button, quick-add action, and selected path badge.
class ItemCategorySelector extends StatelessWidget {
  final List<CategoryEntity> categories;
  final int? selectedCategoryId;
  final String Function(int categoryId) categoryPathBuilder;
  final ValueChanged<int?> onChanged;
  final VoidCallback onBrowseTree;
  final VoidCallback onQuickAdd;

  const ItemCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.categoryPathBuilder,
    required this.onChanged,
    required this.onBrowseTree,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final validCategoryId = categories.any((c) => c.id == selectedCategoryId)
        ? selectedCategoryId
        : null;
    final selectedCat = validCategoryId != null
        ? categories.firstWhere((c) => c.id == validCategoryId)
        : null;
    final selectedPath = validCategoryId != null
        ? categoryPathBuilder(validCategoryId)
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
                  Icons.account_tree_outlined,
                  size: 18,
                  color: AppTheme.deepCobalt,
                ),
                SizedBox(width: 6),
                Text(
                  'الفئة من شجرة الفئات (Category Tree)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: onBrowseTree,
                  icon: const Icon(Icons.account_tree_outlined, size: 15),
                  label: const Text(
                    'تصفح الشجرة',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: onQuickAdd,
                  icon: const Icon(Icons.add_circle_outline, size: 15),
                  label: const Text(
                    'إضافة فئة',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'يمكن تعيين العنصر لأي فئة رئيسية أو متفرعة في شجرة الفئات',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (selectedCat != null && selectedPath != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.deepCobalt.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.deepCobalt.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_tree_rounded,
                  color: AppTheme.deepCobalt,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPath,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepCobalt,
                          fontSize: 13,
                        ),
                      ),
                      if (selectedCat.code != null)
                        Text(
                          'كود الفئة: ${selectedCat.code}',
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
                  tooltip: 'إلغاء تحديد الفئة',
                  onPressed: () => onChanged(null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        DropdownButtonFormField<int?>(
          key: ValueKey(validCategoryId),
          isExpanded: true,
          initialValue: validCategoryId,
          decoration: buildAppInputDecoration(
            label: 'اختر الفئة من القائمة أو تصفح الشجرة',
            icon: Icons.account_tree_outlined,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'بدون فئة (غير مصنف)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ...categories.map((c) {
              final path = categoryPathBuilder(c.id!);
              final isRoot = c.isRoot;
              return DropdownMenuItem<int?>(
                value: c.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRoot
                          ? Icons.folder_outlined
                          : Icons.subdirectory_arrow_left,
                      size: 15,
                      color: isRoot ? AppTheme.deepCobalt : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        path,
                        style: TextStyle(
                          fontWeight: isRoot
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isRoot ? AppTheme.deepCobalt : Colors.black87,
                          fontSize: 12.5,
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

import 'package:flutter/material.dart';

/// A reusable empty state widget that can represent empty search/filter results
/// or an empty collection across different features.
class ItemsEmptyState extends StatelessWidget {
  final bool isFiltered;
  final String? emptyTitle;
  final String? filteredTitle;
  final String? emptySubtitle;
  final String? filteredSubtitle;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onAddItem;

  const ItemsEmptyState({
    super.key,
    this.isFiltered = false,
    this.emptyTitle,
    this.filteredTitle,
    this.emptySubtitle,
    this.filteredSubtitle,
    this.icon = Icons.inventory_2_outlined,
    this.buttonLabel,
    this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = isFiltered
        ? (filteredTitle ?? 'لا توجد نتائج مطابقة لمعايير البحث')
        : (emptyTitle ?? 'لا توجد عناصر مضافة في النظام بعد');

    final subtitle = isFiltered
        ? (filteredSubtitle ?? 'جرّب تغيير كلمات البحث أو إلغاء فلاتر التصفية')
        : (emptySubtitle ?? 'اضغط على زر "إضافة عنصر" للبدء بإضافة أول منتج للمتجر');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            if (onAddItem != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add),
                label: Text(buttonLabel ?? 'إضافة عنصر جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


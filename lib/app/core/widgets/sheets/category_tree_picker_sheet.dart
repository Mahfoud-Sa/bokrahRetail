import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/data/services/categories_service.dart';

/// A reusable bottom sheet modal for searching, browsing, and picking a category
/// from a hierarchical category tree.
class CategoryTreePickerSheet extends StatefulWidget {
  final List<CategoryEntity> categories;
  final int? selectedCategoryId;
  final CategoriesService categoriesService;
  final ValueChanged<int?> onSelected;

  const CategoryTreePickerSheet({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.categoriesService,
    required this.onSelected,
  });

  /// Displays the category tree picker in a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required List<CategoryEntity> categories,
    required int? selectedCategoryId,
    required CategoriesService categoriesService,
    required ValueChanged<int?> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => CategoryTreePickerSheet(
        categories: categories,
        selectedCategoryId: selectedCategoryId,
        categoriesService: categoriesService,
        onSelected: (val) {
          onSelected(val);
          Navigator.pop(sheetCtx);
        },
      ),
    );
  }

  @override
  State<CategoryTreePickerSheet> createState() =>
      _CategoryTreePickerSheetState();
}

class _CategoryTreePickerSheetState extends State<CategoryTreePickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filteredCategories = query.isEmpty
        ? widget.categories
        : widget.categories.where((c) {
            final nameMatch = c.name.toLowerCase().contains(query);
            final codeMatch = c.code?.toLowerCase().contains(query) ?? false;
            final pathMatch = widget.categoriesService
                .getCategoryPath(c.id!, widget.categories)
                .toLowerCase()
                .contains(query);
            return nameMatch || codeMatch || pathMatch;
          }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.actionBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_tree_rounded,
                            color: AppTheme.actionBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تصفح واختيار من شجرة الفئات',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.deepCobalt,
                              ),
                            ),
                            Text(
                              'اضغط على أي فئة لتعيينها للعنصر مباشرة',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث في أسماء أو مسارات الفئات...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),

                // Quick Action: "بدون فئة" (Clear selection)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: widget.selectedCategoryId == null
                          ? AppTheme.actionBlue
                          : AppTheme.border,
                      width: widget.selectedCategoryId == null ? 1.5 : 1,
                    ),
                  ),
                  tileColor: widget.selectedCategoryId == null
                      ? AppTheme.actionBlue.withValues(alpha: 0.06)
                      : Colors.grey[50],
                  leading: Icon(
                    Icons.do_not_disturb_on_outlined,
                    color: widget.selectedCategoryId == null
                        ? AppTheme.actionBlue
                        : Colors.grey,
                  ),
                  title: const Text(
                    'بدون فئة (عنصر غير مصنف)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  trailing: widget.selectedCategoryId == null
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.actionBlue,
                          size: 20,
                        )
                      : null,
                  onTap: () => widget.onSelected(null),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Tree List
                Expanded(
                  child: filteredCategories.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد فئات مطابقة للبحث',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final cat = filteredCategories[index];
                            final isSelected =
                                widget.selectedCategoryId == cat.id;
                            final path = widget.categoriesService
                                .getCategoryPath(cat.id!, widget.categories);
                            final isRoot = cat.isRoot;

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.actionBlue
                                      : AppTheme.border,
                                  width: isSelected ? 1.5 : 0.8,
                                ),
                              ),
                              color: isSelected
                                  ? AppTheme.actionBlue
                                      .withValues(alpha: 0.06)
                                  : Colors.white,
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isRoot
                                      ? AppTheme.deepCobalt
                                          .withValues(alpha: 0.12)
                                      : Colors.grey[200],
                                  child: Icon(
                                    isRoot
                                        ? Icons.folder_rounded
                                        : Icons
                                            .subdirectory_arrow_left_rounded,
                                    size: 16,
                                    color: isRoot
                                        ? AppTheme.deepCobalt
                                        : Colors.grey[700],
                                  ),
                                ),
                                title: Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontWeight: isSelected || isRoot
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppTheme.actionBlue
                                        : AppTheme.deepCobalt,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  path,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: AppTheme.actionBlue,
                                        size: 20,
                                      )
                                    : (cat.code != null
                                        ? Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              cat.code!,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          )
                                        : null),
                                onTap: () => widget.onSelected(cat.id),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


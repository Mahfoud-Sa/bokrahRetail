import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/core/widgets/badges/item_status_badge.dart';

/// A reusable header component containing a search input, department filter,
/// hierarchical category tree filter, and item usage status chips.
class ItemsFilterHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  final List<DepartmentEntity> departments;
  final int? selectedDepartmentId;
  final ValueChanged<int?> onDepartmentChanged;

  final List<CategoryEntity> categories;
  final Map<int, String> categoryPaths;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategoryChanged;

  final ItemUsageStatus? selectedStatus;
  final ValueChanged<ItemUsageStatus?> onStatusChanged;

  final int totalCount;
  final Map<ItemUsageStatus, int> statusCounts;

  final bool showAddButton;
  final VoidCallback? onAddPressed;

  const ItemsFilterHeader({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.departments,
    required this.selectedDepartmentId,
    required this.onDepartmentChanged,
    required this.categories,
    required this.categoryPaths,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.totalCount,
    required this.statusCounts,
    this.showAddButton = false,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.7)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search row with Add button (if showAddButton)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText:
                        'البحث بالاسم، القسم، الفئة، الماركة، أو الباركود...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                ),
              ),
              if (showAddButton && onAddPressed != null) ...[
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onAddPressed,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة عنصر'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Filters Row: Department dropdown + Category Tree dropdown + Status chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. Department filter
                _buildDepartmentDropdown(),

                // 2. Category Tree filter
                _buildCategoryDropdown(),

                // 3. Status filter chips
                _buildStatusChips(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: selectedDepartmentId != null
            ? AppTheme.actionBlue.withValues(alpha: 0.12)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedDepartmentId != null
              ? AppTheme.actionBlue
              : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedDepartmentId,
          hint: const Row(
            children: [
              Icon(Icons.apartment_outlined, size: 14),
              SizedBox(width: 6),
              Text('جميع الأقسام', style: TextStyle(fontSize: 12)),
            ],
          ),
          isDense: true,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'جميع الأقسام',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...departments.map((d) {
              return DropdownMenuItem<int?>(
                value: d.id,
                child: Text(
                  d.name,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
          ],
          onChanged: onDepartmentChanged,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: selectedCategoryId != null
            ? AppTheme.actionBlue.withValues(alpha: 0.12)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedCategoryId != null
              ? AppTheme.actionBlue
              : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedCategoryId,
          hint: const Row(
            children: [
              Icon(Icons.account_tree_outlined, size: 14),
              SizedBox(width: 6),
              Text('شجرة الفئات', style: TextStyle(fontSize: 12)),
            ],
          ),
          isDense: true,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'جميع الفئات',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...categories.map((c) {
              final path = categoryPaths[c.id] ?? c.name;
              return DropdownMenuItem<int?>(
                value: c.id,
                child: Text(
                  path,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
          ],
          onChanged: onCategoryChanged,
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "الكل" Chip
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: FilterChip(
            label: Text(
              'الكل ($totalCount)',
              style: TextStyle(
                fontWeight: selectedStatus == null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            selected: selectedStatus == null,
            onSelected: (_) => onStatusChanged(null),
          ),
        ),

        // Status Specific Chips
        ...ItemUsageStatus.values.map((status) {
          final isSelected = selectedStatus == status;
          final count = statusCounts[status] ?? 0;
          final color = getItemStatusColor(status);
          final icon = getItemStatusIcon(status);

          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: FilterChip(
              avatar: Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : color,
              ),
              label: Text(
                '${status.labelAr} ($count)',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: color,
              onSelected: (selected) {
                onStatusChanged(selected ? status : null);
              },
            ),
          );
        }),
      ],
    );
  }
}


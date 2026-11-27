import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_cubit.dart';
import 'package:bokrah_retail/app/features/categories/presentation/dialogs/delete_category_dialog.dart';

class CategoryTreeNode extends StatelessWidget {
  final CategoryEntity category;
  final CategoriesCubit cubit;
  final int depth;

  const CategoryTreeNode({
    super.key,
    required this.category,
    required this.cubit,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final catId = category.id;
    final children = catId != null
        ? cubit.getSubCategories(catId)
        : <CategoryEntity>[];
    final hasChildren = children.isNotEmpty;
    final isExpanded =
        catId != null && cubit.state.expandedCategoryIds.contains(catId);
    final directItemCount = catId != null ? cubit.getItemCount(catId) : 0;
    final totalItemCount = catId != null
        ? cubit.getTotalItemCountWithSubCategories(catId)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsetsDirectional.only(bottom: 8, start: depth * 22.0),
          decoration: BoxDecoration(
            color: depth == 0
                ? Theme.of(context).cardColor
                : Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: depth == 0
                  ? AppTheme.border
                  : AppTheme.border.withValues(alpha: 0.6),
              width: depth == 0 ? 1.2 : 1,
            ),
            boxShadow: depth == 0
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasChildren && catId != null)
                  IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.expand_more_rounded
                          : Icons.chevron_right_rounded,
                      color: AppTheme.actionBlue,
                    ),
                    onPressed: () => cubit.toggleExpand(catId),
                  )
                else
                  const SizedBox(width: 16),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: depth == 0
                      ? AppTheme.actionBlue.withValues(alpha: 0.12)
                      : AppTheme.paleOrange,
                  child: Icon(
                    depth == 0
                        ? Icons.folder_outlined
                        : Icons.subdirectory_arrow_right_rounded,
                    color: depth == 0
                        ? AppTheme.actionBlue
                        : AppTheme.deepCobalt,
                    size: 18,
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: depth == 0
                          ? FontWeight.bold
                          : FontWeight.w600,
                      fontSize: depth == 0 ? 15 : 14,
                      color: AppTheme.deepCobalt,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (category.code != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category.code!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.description != null &&
                    category.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    category.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    if (hasChildren)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.actionBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${children.length} فئات فرعية',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.actionBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: directItemCount > 0
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hasChildren
                            ? '$directItemCount عنصر مباشر ($totalItemCount إجمالي)'
                            : '$directItemCount عنصر',
                        style: TextStyle(
                          fontSize: 10,
                          color: directItemCount > 0
                              ? AppTheme.success
                              : Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'add_item') {
                  context.push('/add-item', extra: {'categoryId': category.id});
                } else if (action == 'add_sub') {
                  final res = await context.push(
                    '/add-category',
                    extra: {'parentId': category.id},
                  );
                  if (res == true) {
                    cubit.loadCategories();
                  }
                } else if (action == 'edit') {
                  final res = await context.push(
                    '/update-category',
                    extra: category,
                  );
                  if (res == true) {
                    cubit.loadCategories();
                  }
                } else if (action == 'view_items') {
                  context.push('/items', extra: {'categoryId': category.id});
                } else if (action == 'delete') {
                  DeleteCategoryDialog.show(
                    context,
                    category: category,
                    cubit: cubit,
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'add_item',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_box_outlined,
                        color: AppTheme.actionBlue,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text('إضافة عنصر في هذه الفئة'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_sub',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.actionBlue,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text('إضافة فئة فرعية تابعة لها'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'view_items',
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('عرض العناصر التابعة لها'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: AppTheme.actionBlue),
                      SizedBox(width: 8),
                      Text('تعديل الفئة'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: AppTheme.error),
                      SizedBox(width: 8),
                      Text('حذف الفئة'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Recursive child rendering for Category Tree
        if (hasChildren && isExpanded) ...[
          ...children.map(
            (child) => CategoryTreeNode(
              category: child,
              cubit: cubit,
              depth: depth + 1,
            ),
          ),
        ],
      ],
    );
  }
}

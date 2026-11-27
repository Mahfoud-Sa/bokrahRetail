import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_cubit.dart';

class DeleteCategoryDialog extends StatefulWidget {
  final CategoryEntity category;
  final CategoriesCubit cubit;

  const DeleteCategoryDialog({
    super.key,
    required this.category,
    required this.cubit,
  });

  static Future<bool?> show(
    BuildContext context, {
    required CategoryEntity category,
    required CategoriesCubit cubit,
  }) async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/categories',
    )) {
      return null;
    }

    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteCategoryDialog(category: category, cubit: cubit),
    );
  }

  @override
  State<DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<DeleteCategoryDialog> {
  bool _deleteChildren = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final catId = widget.category.id;
    final children = catId != null
        ? widget.cubit.getSubCategories(catId)
        : <CategoryEntity>[];
    final itemCount = catId != null ? widget.cubit.getItemCount(catId) : 0;
    final totalItemCount = catId != null
        ? widget.cubit.getTotalItemCountWithSubCategories(catId)
        : 0;

    return AlertDialog(
      title: const Text('تأكيد حذف الفئة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('هل أنت متأكد من حذف فئة "${widget.category.name}"؟'),
          if (itemCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ يوجد $itemCount عنصر مسجل مباشرة في هذه الفئة ($totalItemCount إجمالي بالفروع).',
              style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'هذه الفئة تحتوي على ${children.length} فئات فرعية تابعة لها:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text(
                'حذف كافة الفئات الفرعية التابعة لها أيضاً',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'عند عدم التحديد، ستتحول الفئات الفرعية إلى فئات رئيسية مستقلة',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              value: _deleteChildren,
              onChanged: _isDeleting
                  ? null
                  : (val) {
                      setState(() => _deleteChildren = val ?? false);
                    },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isDeleting ? null : _handleDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('حذف نهائي'),
        ),
      ],
    );
  }

  Future<void> _handleDelete() async {
    final catId = widget.category.id;
    if (catId == null) return;

    setState(() => _isDeleting = true);

    final success = await widget.cubit.deleteCategory(
      catId,
      deleteSubCategories: _deleteChildren,
    );

    if (!mounted) return;
    setState(() => _isDeleting = false);

    Navigator.pop(context, success);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'تم حذف الفئة بنجاح' : 'حدث خطأ أثناء حذف الفئة',
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
  }
}

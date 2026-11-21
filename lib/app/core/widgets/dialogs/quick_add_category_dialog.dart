import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/data/services/categories_service.dart';

/// A quick modal dialog to create a new category in the tree hierarchy and return the created entity.
class QuickAddCategoryDialog extends StatefulWidget {
  final CategoriesService categoriesService;
  final List<CategoryEntity> categories;
  final int? defaultParentId;

  const QuickAddCategoryDialog({
    super.key,
    required this.categoriesService,
    required this.categories,
    this.defaultParentId,
  });

  static Future<CategoryEntity?> show(
    BuildContext context, {
    required CategoriesService categoriesService,
    required List<CategoryEntity> categories,
    int? defaultParentId,
  }) {
    return showDialog<CategoryEntity?>(
      context: context,
      builder: (dialogCtx) => QuickAddCategoryDialog(
        categoriesService: categoriesService,
        categories: categories,
        defaultParentId: defaultParentId,
      ),
    );
  }

  @override
  State<QuickAddCategoryDialog> createState() => _QuickAddCategoryDialogState();
}

class _QuickAddCategoryDialogState extends State<QuickAddCategoryDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  int? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _selectedParentId = widget.defaultParentId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text(
          'إضافة فئة جديدة في الشجرة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم الفئة *',
                  hintText: 'مثلاً: الهواتف الذكية أو العطور',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _selectedParentId,
                decoration: const InputDecoration(
                  labelText: 'الفئة الأب (الرئيسية)',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      'فئة رئيسية (جذر الشجرة)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...widget.categories.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(
                        widget.categoriesService.getCategoryPath(
                          c.id!,
                          widget.categories,
                        ),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedParentId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'كود الفئة (اختياري)',
                  hintText: 'مثلاً: CAT-PHONE',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;

              final code = _codeCtrl.text.trim();
              final newCat = await widget.categoriesService.saveCategory(
                CategoryEntity(
                  name: name,
                  parentId: _selectedParentId,
                  code: code.isEmpty ? null : code,
                ),
              );

              if (!context.mounted) return;
              Navigator.pop(context, newCat);
            },
            child: const Text('إضافة وتحديد'),
          ),
        ],
      ),
    );
  }
}


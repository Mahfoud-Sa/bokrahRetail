import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_cubit.dart';

class AddEditCategoryDialog extends StatefulWidget {
  final CategoriesCubit cubit;
  final CategoryEntity? category;
  final int? defaultParentId;

  const AddEditCategoryDialog({
    super.key,
    required this.cubit,
    this.category,
    this.defaultParentId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required CategoriesCubit cubit,
    CategoryEntity? category,
    int? defaultParentId,
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
      barrierDismissible: false,
      builder: (_) => AddEditCategoryDialog(
        cubit: cubit,
        category: category,
        defaultParentId: defaultParentId,
      ),
    );
  }

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descController;
  int? _selectedParentId;
  bool _isSaving = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _codeController = TextEditingController(text: widget.category?.code ?? '');
    _descController = TextEditingController(
      text: widget.category?.description ?? '',
    );

    _selectedParentId = _isEditing
        ? widget.category!.parentId
        : (widget.defaultParentId ?? widget.category?.parentId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.cubit.state.categories;

    // Prevent circular reference: category cannot be its own parent or a parent of its descendants
    final invalidParentIds = _isEditing && widget.category!.id != null
        ? {
            widget.category!.id!,
            ...widget.cubit.getDescendantIds(widget.category!.id!),
          }
        : <int>{};

    final availableParents = categories
        .where((c) => !invalidParentIds.contains(c.id))
        .toList();

    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل الفئة' : 'إضافة فئة جديدة',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الفئة *',
                  prefixIcon: Icon(Icons.account_tree_outlined),
                  hintText: 'مثلاً: الهواتف الذكية أو لابتوب',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'يرجى إدخال اسم الفئة'
                    : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<int?>(
                initialValue: _selectedParentId,
                decoration: const InputDecoration(
                  labelText: 'الفئة الرئيسية (الأب)',
                  prefixIcon: Icon(Icons.subdirectory_arrow_right),
                  hintText: 'اختر الفئة الأب لبناء الشجرة الهرمية',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      'فئة رئيسية (جذر الشجرة)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...availableParents.map((p) {
                    final path = widget.cubit.getCategoryPath(p.id!);
                    return DropdownMenuItem<int?>(
                      value: p.id,
                      child: Text(path),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() => _selectedParentId = val);
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'كود الفئة (اختياري)',
                  prefixIcon: Icon(Icons.tag),
                  hintText: 'مثلاً: CAT-PHONE',
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'وصف الفئة (اختياري)',
                  prefixIcon: Icon(Icons.description_outlined),
                  hintText: 'وصف لمواصفات وتصنيف الفئة',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'حفظ التعديلات' : 'إضافة الفئة'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim().isEmpty
        ? null
        : _codeController.text.trim();
    final desc = _descController.text.trim().isEmpty
        ? null
        : _descController.text.trim();

    setState(() => _isSaving = true);

    bool success = false;
    if (_isEditing) {
      final updated = widget.category!.copyWith(
        name: name,
        parentId: _selectedParentId,
        clearParent: _selectedParentId == null,
        code: code,
        description: desc,
      );
      success = await widget.cubit.updateCategory(updated);
    } else {
      final newCat = CategoryEntity(
        name: name,
        parentId: _selectedParentId,
        code: code,
        description: desc,
      );
      final result = await widget.cubit.saveCategory(newCat);
      success = result != null;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    Navigator.pop(context, success);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_isEditing ? 'تم تحديث الفئة بنجاح' : 'تمت إضافة الفئة بنجاح')
              : 'حدث خطأ أثناء حفظ الفئة',
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
  }
}

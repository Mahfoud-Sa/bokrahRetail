import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_cubit.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_state.dart';

class UpdateCategoryPage extends StatefulWidget {
  final CategoryEntity category;

  const UpdateCategoryPage({super.key, required this.category});

  @override
  State<UpdateCategoryPage> createState() => _UpdateCategoryPageState();
}

class _UpdateCategoryPageState extends State<UpdateCategoryPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descController;
  int? _selectedParentId;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameController = TextEditingController(text: c.name);
    _codeController = TextEditingController(text: c.code ?? '');
    _descController = TextEditingController(text: c.description ?? '');
    _selectedParentId = c.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/update-category',
    )) {
      return;
    }
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim().isEmpty
        ? null
        : _codeController.text.trim().toUpperCase();
    final desc = _descController.text.trim().isEmpty
        ? null
        : _descController.text.trim();

    final updatedCategory = widget.category.copyWith(
      name: name,
      parentId: _selectedParentId,
      clearParent: _selectedParentId == null,
      code: code,
      description: desc,
    );

    final success = await context.read<CategoriesCubit>().updateCategory(
      updatedCategory,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات الفئة بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          try {
            context.go('/categories');
          } catch (_) {}
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تحديث الفئة'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<CategoriesCubit, bool>(
      (cubit) => cubit.state.isSaving,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.mainBackground,
        appBar: AppBar(
          title: Text('تعديل فئة: ${widget.category.name}'),
          backgroundColor: AppTheme.deepCobalt,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                try {
                  context.go('/categories');
                } catch (_) {}
              }
            },
          ),
        ),
        body: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            final cubit = context.read<CategoriesCubit>();
            final catId = widget.category.id;

            // Prevent circular reference: category cannot be its own parent or a parent of its descendants
            final invalidParentIds = catId != null
                ? {catId, ...cubit.getDescendantIds(catId)}
                : <int>{};

            final availableParents = state.categories
                .where((c) => !invalidParentIds.contains(c.id))
                .toList();

            final directItemCount = catId != null
                ? cubit.getItemCount(catId)
                : 0;
            final totalItemCount = catId != null
                ? cubit.getTotalItemCountWithSubCategories(catId)
                : 0;
            final subCategoriesCount = catId != null
                ? cubit.getSubCategories(catId).length
                : 0;

            final currentPath = catId != null
                ? cubit.getCategoryPath(catId)
                : widget.category.name;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Form(
                    key: _formKey,
                    child: ResponsiveFormGrid(
                      // Top overview metrics header
                      header: Row(
                        children: [
                          Expanded(
                            child: StatMetricCard(
                              title: 'العناصر المباشرة',
                              value: directItemCount.toString(),
                              icon: Icons.inventory_2_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatMetricCard(
                              title: 'إجمالي العناصر بالفروع',
                              value: totalItemCount.toString(),
                              icon: Icons.category_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatMetricCard(
                              title: 'الفئات الفرعية',
                              value: subCategoriesCount.toString(),
                              icon: Icons.account_tree_outlined,
                            ),
                          ),
                        ],
                      ),
                      sections: [
                        // Card 1: Basic Information
                        FormSectionCard(
                          title: 'بيانات الفئة الأساسية',
                          icon: Icons.category_outlined,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'اسم الفئة *',
                                hintText:
                                    'مثال: الهواتف الذكية، الأجهزة اللوحية، العطور',
                                prefixIcon: Icon(Icons.account_tree_outlined),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'يرجى إدخال اسم الفئة'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _codeController,
                              decoration: const InputDecoration(
                                labelText: 'كود الفئة (اختياري)',
                                hintText: 'مثال: CAT-PHONE، SMART-01',
                                prefixIcon: Icon(Icons.tag),
                              ),
                            ),
                          ],
                        ),

                        // Card 2: Hierarchy Placement
                        FormSectionCard(
                          title: 'الموقع في شجرة الفئات (الهيكلية)',
                          icon: Icons.subdirectory_arrow_right,
                          children: [
                            DropdownButtonFormField<int?>(
                              isExpanded: true,
                              initialValue: _selectedParentId,
                              decoration: const InputDecoration(
                                labelText: 'الفئة الرئيسية (الأب)',
                                hintText:
                                    'اختر الفئة الأب أو اتركها كفئة رئيسية جذرية',
                                prefixIcon: Icon(Icons.folder_open_outlined),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text(
                                    'فئة رئيسية (جذر الشجرة)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...availableParents.map((p) {
                                  final path = cubit.getCategoryPath(p.id!);
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
                            const SizedBox(height: 12),
                            Text(
                              'تم استبعاد هذه الفئة وجميع الفئات الفرعية التابعة لها تلقائياً لتجنب الحلقات الدائرية في الشجرة.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),

                        // Card 3: Description
                        FormSectionCard(
                          title: 'الوصف والتفاصيل الإضافية',
                          icon: Icons.description_outlined,
                          children: [
                            TextFormField(
                              controller: _descController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'وصف الفئة (اختياري)',
                                hintText:
                                    'أدخل وصفاً توضيحياً لمحتويات أو مواصفات هذه الفئة...',
                                prefixIcon: Icon(Icons.notes_outlined),
                              ),
                            ),
                          ],
                        ),

                        // Card 4: System Information & Hierarchy Path
                        FormSectionCard(
                          title: 'معلومات النظام والمسار الشجري',
                          icon: Icons.info_outline,
                          children: [
                            InfoKeyValueRow(
                              icon: Icons.route_outlined,
                              label: 'المسار الشجري الحالي',
                              value: currentPath,
                            ),
                            const SizedBox(height: 12),
                            InfoKeyValueRow(
                              icon: Icons.fingerprint,
                              label: 'معرّف الفئة (ID)',
                              value: catId != null ? '#$catId' : 'غير محدد',
                              valueColor: AppTheme.warmOrange,
                            ),
                            const SizedBox(height: 12),
                            InfoKeyValueRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'تاريخ الإنشاء',
                              value:
                                  '${widget.category.createdAt.year}/${widget.category.createdAt.month.toString().padLeft(2, '0')}/${widget.category.createdAt.day.toString().padLeft(2, '0')}',
                            ),
                          ],
                        ),
                      ],
                      footer: FormActionBar(
                        isSubmitting: isSaving,
                        submitLabel: 'حفظ التعديلات',
                        onSubmit: _submit,
                        onCancel: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            try {
                              context.go('/categories');
                            } catch (_) {}
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

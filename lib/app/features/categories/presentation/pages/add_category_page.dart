import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_cubit.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_state.dart';

class AddCategoryPage extends StatefulWidget {
  final int? defaultParentId;

  const AddCategoryPage({super.key, this.defaultParentId});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  int? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _selectedParentId = widget.defaultParentId;
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
      returnRoute: '/add-category',
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

    final newCategory = CategoryEntity(
      name: name,
      parentId: _selectedParentId,
      code: code,
      description: desc,
    );

    final saved = await context.read<CategoriesCubit>().saveCategory(
      newCategory,
    );

    if (mounted) {
      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة الفئة بنجاح'),
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
            content: Text('حدث خطأ أثناء إضافة الفئة'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.deepCobalt.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppTheme.deepCobalt),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
          title: const Text('إضافة فئة جديدة'),
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
            final availableParents = state.categories;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Form(
                    key: _formKey,
                    child: ResponsiveFormGrid(
                      sections: [
                        // Card 1: Basic Information
                        FormSectionCard(
                          title: 'بيانات الفئة الأساسية (مطلوبة)',
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
                              'تحديد الفئة الأب يساعد في تنظيم الشجرة الهرمية لتسهيل فلترة المنتجات وعرض التقارير بدقة.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),

                        // Card 3: Description & Notes
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

                        // Card 4: Guidelines & Help
                        FormSectionCard(
                          title: 'إرشادات تنظيم الفئات',
                          icon: Icons.lightbulb_outlined,
                          children: [
                            _buildGuidelineItem(
                              icon: Icons.account_tree_outlined,
                              title: 'الفئات الرئيسية (الجذر)',
                              description:
                                  'تمثل الأقسام والخطوط العريضة لمنتجاتك (مثل: الإلكترونيات، الأزياء، الأغذية).',
                            ),
                            const SizedBox(height: 12),
                            _buildGuidelineItem(
                              icon: Icons.subdirectory_arrow_right,
                              title: 'الفئات الفرعية',
                              description:
                                  'تساعد في تفريع وتصنيف المنتجات بدقة، مما يسهل الوصول السريع لها في نقطة البيع (POS).',
                            ),
                            const SizedBox(height: 12),
                            _buildGuidelineItem(
                              icon: Icons.edit_note_outlined,
                              title: 'المرونة والتعديل',
                              description:
                                  'يمكنك لاحقاً تعديل الموقع الهيكلي أو الاسم أو نقل المنتجات بين الفئات بدون أي قيود.',
                            ),
                          ],
                        ),
                      ],
                      footer: FormActionBar(
                        isSubmitting: isSaving,
                        submitLabel: 'حفظ الفئة',
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

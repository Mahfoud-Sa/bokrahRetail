import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/categories/data/services/categories_service.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoriesPage extends StatefulWidget {
  final bool showAppBar;
  const CategoriesPage({super.key, this.showAppBar = true});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoriesService _categoriesService = CategoriesService();
  final ItemsService _itemsService = ItemsService();
  final TextEditingController _searchController = TextEditingController();

  List<CategoryEntity> _categories = [];
  List<ItemEntity> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final Set<int> _expandedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cats = await _categoriesService.getAllCategories();
    final items = await _itemsService.getAllItems();

    setState(() {
      _categories = cats;
      _items = items;
      _isLoading = false;
      // Expand all categories by default so tree is visible
      for (final c in cats) {
        if (c.id != null) {
          _expandedCategoryIds.add(c.id!);
        }
      }
    });
  }

  int _getItemCount(int categoryId) {
    return _items.where((i) => i.effectiveCategoryId == categoryId).length;
  }

  int _getTotalItemCountWithSubCategories(int categoryId) {
    final descendants =
        _categoriesService.getDescendantIds(categoryId, _categories);
    final allIds = {categoryId, ...descendants};
    return _items
        .where((i) => allIds.contains(i.effectiveCategoryId))
        .length;
  }

  Future<void> _showAddEditCategoryDialog({
    CategoryEntity? category,
    int? defaultParentId,
  }) async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/categories',
    )) {
      return;
    }

    final isEditing = category != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: category?.name ?? '');
    final codeController = TextEditingController(text: category?.code ?? '');
    final descController =
        TextEditingController(text: category?.description ?? '');

    int? selectedParentId = isEditing
        ? category.parentId
        : (defaultParentId ?? category?.parentId);

    // Prevent circular reference by excluding self and descendants
    final invalidParentIds = isEditing && category.id != null
        ? {
            category.id!,
            ..._categoriesService.getDescendantIds(category.id!, _categories),
          }
        : <int>{};

    final availableParents = _categories
        .where((c) => !invalidParentIds.contains(c.id))
        .toList();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              isEditing ? 'تعديل الفئة' : 'إضافة فئة جديدة',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
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

                    // Self-joining Parent Category Selector
                    DropdownButtonFormField<int?>(
                      value: selectedParentId,
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
                          final path = _categoriesService.getCategoryPath(
                            p.id!,
                            _categories,
                          );
                          return DropdownMenuItem<int?>(
                            value: p.id,
                            child: Text(path),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedParentId = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'كود الفئة (اختياري)',
                        prefixIcon: Icon(Icons.tag),
                        hintText: 'مثلاً: CAT-PHONE',
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: descController,
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
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final name = nameController.text.trim();
                  final code = codeController.text.trim().isEmpty
                      ? null
                      : codeController.text.trim();
                  final desc = descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim();

                  bool success = false;
                  if (isEditing) {
                    final updated = category.copyWith(
                      name: name,
                      parentId: selectedParentId,
                      clearParent: selectedParentId == null,
                      code: code,
                      description: desc,
                    );
                    success =
                        await _categoriesService.updateCategory(updated);
                  } else {
                    final newCat = CategoryEntity(
                      name: name,
                      parentId: selectedParentId,
                      code: code,
                      description: desc,
                    );
                    final result =
                        await _categoriesService.saveCategory(newCat);
                    success = result != null;
                  }

                  if (mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? (isEditing
                                  ? 'تم تحديث الفئة بنجاح'
                                  : 'تمت إضافة الفئة بنجاح')
                              : 'حدث خطأ أثناء حفظ الفئة',
                        ),
                        backgroundColor:
                            success ? AppTheme.success : AppTheme.error,
                      ),
                    );
                    _loadData();
                  }
                },
                child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة الفئة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(CategoryEntity category) async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/categories',
    )) {
      return;
    }

    final children =
        _categoriesService.getSubCategories(category.id!, _categories);
    final itemCount = _getItemCount(category.id!);
    final totalItemCount =
        _getTotalItemCountWithSubCategories(category.id!);

    bool deleteChildren = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setConfirmState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد حذف الفئة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('هل أنت متأكد من حذف فئة "${category.name}"؟'),
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
                    value: deleteChildren,
                    onChanged: (val) {
                      setConfirmState(() => deleteChildren = val ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حذف نهائي'),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && category.id != null) {
      final success = await _categoriesService.deleteCategory(
        category.id!,
        deleteSubCategories: deleteChildren,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'تم حذف الفئة بنجاح' : 'حدث خطأ أثناء حذف الفئة',
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootCategories = _categoriesService
        .getRootCategories(_categories)
        .where((root) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final hasMatchInTree = _hasMatchInSubtree(root.id!, q);
      return root.name.toLowerCase().contains(q) ||
          (root.code?.toLowerCase().contains(q) ?? false) ||
          hasMatchInTree;
    }).toList();

    final bodyContent = Column(
      children: [
        _buildHeaderToolbar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : rootCategories.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rootCategories.length,
                    itemBuilder: (context, index) {
                      final root = rootCategories[index];
                      return _buildCategoryNode(root, depth: 0);
                    },
                  ),
                ),
        ),
      ],
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: widget.showAppBar
          ? Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                title: const Text(
                  'شجرة الفئات والتصنيفات (Category Tree)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: FilledButton.icon(
                      onPressed: () => _showAddEditCategoryDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة فئة رئيسية'),
                    ),
                  ),
                ],
              ),
              body: bodyContent,
            )
          : bodyContent,
    );
  }

  bool _hasMatchInSubtree(int catId, String query) {
    final children =
        _categoriesService.getSubCategories(catId, _categories);
    for (final child in children) {
      if (child.name.toLowerCase().contains(query) ||
          (child.code?.toLowerCase().contains(query) ?? false)) {
        return true;
      }
      if (_hasMatchInSubtree(child.id!, query)) return true;
    }
    return false;
  }

  Widget _buildHeaderToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'البحث في شجرة الفئات بالاسم أو الكود...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
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
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => _showAddEditCategoryDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة فئة رئيسية'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 72,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد فئات مطابقة لمعايير البحث'
                : 'لا توجد فئات مسجلة في شجرة التصنيف بعد',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'جرّب كتابة كلمة بحث أخرى'
                : 'ابدأ ببناء شجرة الفئات عبر إضافة فئات رئيسية وفرعية متفرعة',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddEditCategoryDialog(),
            icon: const Icon(Icons.add),
            label: const Text('إضافة أول فئة رئيسية'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryNode(CategoryEntity cat, {required int depth}) {
    final children =
        _categoriesService.getSubCategories(cat.id!, _categories);
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expandedCategoryIds.contains(cat.id);
    final directItemCount = _getItemCount(cat.id!);
    final totalItemCount = _getTotalItemCountWithSubCategories(cat.id!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            bottom: 8,
            right: depth * 22.0, // Indent based on depth in hierarchy
          ),
          decoration: BoxDecoration(
            color: depth == 0
                ? Theme.of(context).cardColor
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: depth == 0 ? AppTheme.border : Colors.grey[300]!,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasChildren)
                  IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.expand_more_rounded
                          : Icons.chevron_left_rounded,
                      color: AppTheme.actionBlue,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedCategoryIds.remove(cat.id);
                        } else {
                          _expandedCategoryIds.add(cat.id!);
                        }
                      });
                    },
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
                        : Icons.subdirectory_arrow_left_rounded,
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
                    cat.name,
                    style: TextStyle(
                      fontWeight:
                          depth == 0 ? FontWeight.bold : FontWeight.w600,
                      fontSize: depth == 0 ? 15 : 14,
                      color: AppTheme.deepCobalt,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (cat.code != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cat.code!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cat.description != null &&
                    cat.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    cat.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                            : Colors.grey[100],
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
                              : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'add_item') {
                  context.push('/add-item', extra: {'categoryId': cat.id});
                } else if (action == 'add_sub') {
                  _showAddEditCategoryDialog(defaultParentId: cat.id);
                } else if (action == 'edit') {
                  _showAddEditCategoryDialog(category: cat);
                } else if (action == 'view_items') {
                  context.push('/items', extra: {'categoryId': cat.id});
                } else if (action == 'delete') {
                  _deleteCategory(cat);
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
            (child) => _buildCategoryNode(child, depth: depth + 1),
          ),
        ],
      ],
    );
  }
}

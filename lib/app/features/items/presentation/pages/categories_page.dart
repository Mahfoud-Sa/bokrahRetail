import 'package:bokrah_retail/app/features/items/data/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/items/data/services/categories_service.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/features/items/presentation/pages/items_page.dart';
import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoriesService _categoriesService = CategoriesService();
  final ItemsService _itemsService = ItemsService();
  List<CategoryEntity> _categories = [];
  Map<int, int> _categoryItemCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final categories = await _categoriesService.getAllCategories();
    final items = await _itemsService.getAllItems();

    // Calculate item counts per category
    final Map<int, int> counts = {};
    for (var item in items) {
      if (item.categoryId != null) {
        counts[item.categoryId!] = (counts[item.categoryId!] ?? 0) + 1;
      }
    }

    setState(() {
      _categories = categories;
      _categoryItemCounts = counts;
      _isLoading = false;
    });
  }

  Future<void> _showAddEditDialog({CategoryEntity? category}) async {
    if (!await AppAccessGuard.requireRestaurant(
      context: context,
      returnRoute: '/categories',
    )) {
      return;
    }
    final isEditing = category != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(isEditing ? 'تعديل الفئة' : 'إضافة فئة جديدة'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newCategory = CategoryEntity(
                    id: category?.id,
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    createdAt: category?.createdAt,
                  );

                  bool success;
                  if (isEditing) {
                    success = await _categoriesService.updateCategory(
                      newCategory,
                    );
                  } else {
                    success = await _categoriesService.saveCategory(
                      newCategory,
                    );
                  }

                  if (success) {
                    Navigator.pop(context);
                    _loadData();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D64),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'تحديث' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(CategoryEntity category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف فئة "${category.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && category.id != null) {
      await _categoriesService.deleteCategory(category.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'الفئات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF2E7D64),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddEditDialog(),
              tooltip: 'إضافة فئة جديدة',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد فئات بعد',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة فئة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D64),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final itemCount = _categoryItemCounts[category.id] ?? 0;
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF2E7D64,
                          ).withOpacity(0.1),
                          child: const Icon(
                            Icons.category,
                            color: Color(0xFF2E7D64),
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '${category.description ?? 'لا يوجد وصف'}\n$itemCount عنصر',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        onTap: () {
                          // View items in this category
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ItemsPage(categoryId: category.id),
                            ),
                          );
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddEditDialog(category: category);
                            }
                            if (value == 'delete') _deleteCategory(category);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Color(0xFF2E7D64)),
                                  SizedBox(width: 8),
                                  Text('تعديل'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('حذف'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditDialog(),
          backgroundColor: const Color(0xFF2E7D64),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

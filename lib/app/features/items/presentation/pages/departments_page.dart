import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/items/data/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/items/data/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/data/services/departments_service.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DepartmentsPage extends StatefulWidget {
  final bool showAppBar;
  const DepartmentsPage({super.key, this.showAppBar = true});

  @override
  State<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  final DepartmentsService _departmentsService = DepartmentsService();
  final ItemsService _itemsService = ItemsService();
  final TextEditingController _searchController = TextEditingController();

  List<DepartmentEntity> _departments = [];
  List<ItemEntity> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';

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
    final depts = await _departmentsService.getAllDepartments();
    final items = await _itemsService.getAllItems();

    setState(() {
      _departments = depts;
      _items = items;
      _isLoading = false;
    });
  }

  int _getItemCount(int departmentId) {
    return _items
        .where((i) => (i.departmentId ?? i.categoryId) == departmentId)
        .length;
  }

  List<DepartmentEntity> get _filteredDepartments {
    if (_searchQuery.trim().isEmpty) return _departments;
    final q = _searchQuery.trim().toLowerCase();
    return _departments.where((d) {
      final nameMatch = d.name.toLowerCase().contains(q);
      final codeMatch = d.code?.toLowerCase().contains(q) ?? false;
      final descMatch = d.description?.toLowerCase().contains(q) ?? false;
      return nameMatch || codeMatch || descMatch;
    }).toList();
  }

  Future<void> _showAddEditDepartmentDialog({
    DepartmentEntity? department,
  }) async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/departments',
    )) {
      return;
    }

    final isEditing = department != null;
    final formKey = GlobalKey<FormState>();

    final nameController =
        TextEditingController(text: department?.name ?? '');
    final codeController =
        TextEditingController(text: department?.code ?? '');
    final descController =
        TextEditingController(text: department?.description ?? '');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              isEditing ? 'تعديل القسم' : 'إضافة قسم جديد',
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
                        labelText: 'اسم القسم *',
                        prefixIcon: Icon(Icons.category_outlined),
                        hintText: 'مثلاً: الأجهزة الإلكترونية أو الهواتف',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'يرجى إدخال اسم القسم'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'كود القسم (اختياري)',
                        prefixIcon: Icon(Icons.tag),
                        hintText: 'مثلاً: ELEC أو PHONE',
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'وصف القسم (اختياري)',
                        prefixIcon: Icon(Icons.description_outlined),
                        hintText: 'وصف للمنتجات والأصناف التابعة لهذا القسم',
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
                    final updated = department.copyWith(
                      name: name,
                      code: code,
                      description: desc,
                    );
                    success =
                        await _departmentsService.updateDepartment(updated);
                  } else {
                    final newDept = DepartmentEntity(
                      name: name,
                      code: code,
                      description: desc,
                    );
                    final result =
                        await _departmentsService.saveDepartment(newDept);
                    success = result != null;
                  }

                  if (mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? (isEditing
                                  ? 'تم تحديث القسم بنجاح'
                                  : 'تمت إضافة القسم بنجاح')
                              : 'حدث خطأ أثناء حفظ القسم',
                        ),
                        backgroundColor:
                            success ? AppTheme.success : AppTheme.error,
                      ),
                    );
                    _loadData();
                  }
                },
                child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة القسم'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDepartment(DepartmentEntity department) async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/departments',
    )) {
      return;
    }

    final itemCount = _getItemCount(department.id!);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد حذف القسم'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('هل أنت متأكد من حذف قسم "${department.name}"؟'),
              if (itemCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '⚠️ يوجد $itemCount عنصر مسجل ضمن هذا القسم.',
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
    );

    if (confirmed == true && department.id != null) {
      final success = await _departmentsService.deleteDepartment(department.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'تم حذف القسم بنجاح' : 'حدث خطأ أثناء حذف القسم',
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
    final filtered = _filteredDepartments;

    final bodyContent = Column(
      children: [
        _buildHeaderToolbar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final dept = filtered[index];
                      return _buildDepartmentCard(dept);
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
                  'إدارة الأقسام (Departments)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: FilledButton.icon(
                      onPressed: () => _showAddEditDepartmentDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة قسم'),
                    ),
                  ),
                ],
              ),
              body: bodyContent,
            )
          : bodyContent,
    );
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
                hintText: 'البحث عن قسم بالاسم أو الكود...',
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
            onPressed: () => _showAddEditDepartmentDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة قسم'),
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
            Icons.category_outlined,
            size: 72,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد أقسام مطابقة لمعايير البحث'
                : 'لا توجد أقسام مسجلة في النظام بعد',
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
                : 'أنشئ الأقسام لتصنيف وتنظيم العناصر بدقة (قسم لكل مجموعة عناصر)',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDepartmentDialog(),
            icon: const Icon(Icons.add),
            label: const Text('إضافة قسم جديد'),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(DepartmentEntity dept) {
    final itemCount = _getItemCount(dept.id!);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.actionBlue.withValues(alpha: 0.12),
          child: const Icon(
            Icons.category_rounded,
            color: AppTheme.actionBlue,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                dept.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.deepCobalt,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dept.code != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dept.code!,
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
            if (dept.description != null && dept.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                dept.description!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: itemCount > 0
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$itemCount عنصر في هذا القسم',
                style: TextStyle(
                  fontSize: 11,
                  color: itemCount > 0 ? AppTheme.success : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              tooltip: 'عرض عناصر القسم',
              onPressed: () {
                context.push('/items', extra: dept.id);
              },
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'add_item') {
                  context.push('/add-item', extra: {'departmentId': dept.id});
                } else if (action == 'view_items') {
                  context.push('/items', extra: dept.id);
                } else if (action == 'edit') {
                  _showAddEditDepartmentDialog(department: dept);
                } else if (action == 'delete') {
                  _deleteDepartment(dept);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'add_item',
                  child: Row(
                    children: [
                      Icon(Icons.add_box_outlined, size: 18, color: AppTheme.actionBlue),
                      SizedBox(width: 8),
                      Text('إضافة عنصر في هذا القسم'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'view_items',
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('عرض العناصر'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: AppTheme.actionBlue),
                      SizedBox(width: 8),
                      Text('تعديل القسم'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: AppTheme.error),
                      SizedBox(width: 8),
                      Text('حذف القسم'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

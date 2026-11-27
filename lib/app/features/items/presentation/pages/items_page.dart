import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/features/categories/domain/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/categories/data/services/categories_service.dart';
import 'package:bokrah_retail/app/features/departments/data/services/departments_service.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/features/units/data/datasources/unit_local_datasource.dart';
import 'package:bokrah_retail/app/features/units/data/repositories/unit_repository_impl.dart';
import 'package:bokrah_retail/app/features/units/domain/usecases/unit_usecases.dart';

import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

class ItemsPage extends StatefulWidget {
  final int? departmentId;
  final int? categoryId;
  final bool showAppBar;

  const ItemsPage({
    super.key,
    this.departmentId,
    this.categoryId,
    this.showAppBar = true,
  });

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final ItemsService _itemsService = ItemsService();
  final DepartmentsService _departmentsService =
      singelton.isRegistered<DepartmentsService>()
      ? singelton<DepartmentsService>()
      : DepartmentsService();
  final CategoriesService _categoriesService = CategoriesService();
  final TextEditingController _searchController = TextEditingController();

  List<ItemEntity> _items = [];
  List<DepartmentEntity> _departments = [];
  List<CategoryEntity> _categories = [];
  Map<int, String> _baseUnits = {};
  Map<int, String> _departmentNames = {};
  Map<int, String> _categoryPaths = {};

  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  ItemUsageStatus? _selectedStatusFilter;
  int? _selectedDepartmentFilter;
  int? _selectedCategoryFilter;
  Set<int>? _matchingCategoryIds;

  @override
  void initState() {
    super.initState();
    _selectedDepartmentFilter = widget.departmentId;
    _selectedCategoryFilter = widget.categoryId;
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allItems = await _itemsService.getAllItems();
      final departments = await _departmentsService.getAllDepartments();
      final categories = await _categoriesService.getAllCategories();
      final baseUnitsMap = await _loadBaseUnits();

      // Pre-calculate fast lookup maps for display and search (O(1) lookups)
      final deptNamesMap = <int, String>{};
      for (final d in departments) {
        if (d.id != null) deptNamesMap[d.id!] = d.name;
      }

      final catPathsMap = <int, String>{};
      for (final c in categories) {
        if (c.id != null) {
          catPathsMap[c.id!] = _categoriesService.getCategoryPath(
            c.id!,
            categories,
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _items = allItems;
        _departments = departments;
        _categories = categories;
        _baseUnits = baseUnitsMap;
        _departmentNames = deptNamesMap;
        _categoryPaths = catPathsMap;
        _isLoading = false;
        _updateMatchingCategoryIds();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء تحميل البيانات: $e';
      });
    }
  }

  Future<Map<int, String>> _loadBaseUnits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unitDataSource = UnitLocalDataSourceImpl(sharedPreferences: prefs);
      final unitRepo = UnitRepositoryImpl(localDataSource: unitDataSource);
      final getAllUnits = GetAllUnitsUseCase(unitRepo);
      final allUnits = await getAllUnits();

      final baseUnitsMap = <int, String>{};
      for (final unit in allUnits) {
        if (unit.factor == 1.0) {
          baseUnitsMap[unit.itemId] = unit.name;
        }
      }
      return baseUnitsMap;
    } catch (_) {
      return {};
    }
  }

  void _updateMatchingCategoryIds() {
    if (_selectedCategoryFilter != null) {
      final descendants = _categoriesService.getDescendantIds(
        _selectedCategoryFilter!,
        _categories,
      );
      _matchingCategoryIds = {_selectedCategoryFilter!, ...descendants};
    } else {
      _matchingCategoryIds = null;
    }
  }

  void _onCategoryFilterChanged(int? categoryId) {
    setState(() {
      _selectedCategoryFilter = categoryId;
      _updateMatchingCategoryIds();
    });
  }

  String _getDepartmentName(int? id) =>
      id != null ? (_departmentNames[id] ?? 'بدون قسم') : 'بدون قسم';

  String _getCategoryPath(int? id) =>
      id != null ? (_categoryPaths[id] ?? 'بدون فئة') : 'بدون فئة';

  Map<ItemUsageStatus, int> get _statusCounts {
    final counts = <ItemUsageStatus, int>{};
    for (final status in ItemUsageStatus.values) {
      counts[status] = _items.where((i) => i.usageStatus == status).length;
    }
    return counts;
  }

  List<ItemEntity> get _filteredItems {
    final query = _searchQuery.trim().toLowerCase();
    final hasQuery = query.isNotEmpty;

    return _items.where((item) {
      // 1. Department filter
      if (_selectedDepartmentFilter != null &&
          item.effectiveDepartmentId != _selectedDepartmentFilter) {
        return false;
      }

      // 2. Category tree filter (uses pre-calculated descendant set for O(1) matching)
      if (_matchingCategoryIds != null) {
        if (item.effectiveCategoryId == null ||
            !_matchingCategoryIds!.contains(item.effectiveCategoryId)) {
          return false;
        }
      }

      // 3. Usage Status filter
      if (_selectedStatusFilter != null &&
          item.usageStatus != _selectedStatusFilter) {
        return false;
      }

      // 4. Search query filter
      if (hasQuery) {
        final nameMatch = item.name.toLowerCase().contains(query);
        final subnameMatch =
            item.effectiveSubname?.toLowerCase().contains(query) ?? false;
        final brandMatch = item.brand?.toLowerCase().contains(query) ?? false;
        final companyMatch =
            item.effectiveCompany?.toLowerCase().contains(query) ?? false;
        final shortDescMatch =
            item.shortDescription?.toLowerCase().contains(query) ?? false;
        final fullDescMatch =
            item.effectiveFullDescription?.toLowerCase().contains(query) ??
            false;
        final barcodeMatch = item.barcodes.any(
          (b) => b.toLowerCase().contains(query),
        );
        final deptMatch =
            item.effectiveDepartmentId != null &&
            _getDepartmentName(
              item.effectiveDepartmentId,
            ).toLowerCase().contains(query);
        final catMatch =
            item.effectiveCategoryId != null &&
            _getCategoryPath(
              item.effectiveCategoryId,
            ).toLowerCase().contains(query);

        if (!nameMatch &&
            !subnameMatch &&
            !brandMatch &&
            !companyMatch &&
            !shortDescMatch &&
            !fullDescMatch &&
            !barcodeMatch &&
            !deptMatch &&
            !catMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _navigateToAddEdit({ItemEntity? item}) async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/items',
    )) {
      return;
    }
    final dynamic extraData =
        item ??
        ((_selectedDepartmentFilter != null || _selectedCategoryFilter != null)
            ? {
                'departmentId': _selectedDepartmentFilter,
                'categoryId': _selectedCategoryFilter,
              }
            : null);

    if (!mounted) return;
    final result = await context.push<bool>('/add-item', extra: extraData);
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteItem(ItemEntity item) async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/items',
    )) {
      return;
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'هل أنت متأكد من حذف "${item.name}" نهائياً من النظام؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && item.id != null) {
      final success = await _itemsService.deleteItem(item.id!);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف العنصر بنجاح'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
        _loadData();
      }
    }
  }

  void _showItemDetails(ItemEntity item) {
    ItemDetailsSheet.show(
      context,
      item: item,
      departmentName: _getDepartmentName(item.effectiveDepartmentId),
      categoryPath: _getCategoryPath(item.effectiveCategoryId),
      baseUnitName: _baseUnits[item.id],
      onEdit: () => _navigateToAddEdit(item: item),
      onDelete: () => _deleteItem(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final isFiltered =
        _searchQuery.isNotEmpty ||
        _selectedStatusFilter != null ||
        _selectedDepartmentFilter != null ||
        _selectedCategoryFilter != null;

    final content = Column(
      children: [
        // Top Filter Bar
        ItemsFilterHeader(
          searchController: _searchController,
          searchQuery: _searchQuery,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          departments: _departments,
          selectedDepartmentId: _selectedDepartmentFilter,
          onDepartmentChanged: (val) =>
              setState(() => _selectedDepartmentFilter = val),
          categories: _categories,
          categoryPaths: _categoryPaths,
          selectedCategoryId: _selectedCategoryFilter,
          onCategoryChanged: _onCategoryFilterChanged,
          selectedStatus: _selectedStatusFilter,
          onStatusChanged: (status) =>
              setState(() => _selectedStatusFilter = status),
          totalCount: _items.length,
          statusCounts: _statusCounts,
          showAddButton: !widget.showAppBar,
          onAddPressed: () => _navigateToAddEdit(),
        ),

        // Items List, Empty State, Error or Loading
        Expanded(child: _buildBody(filtered, isFiltered)),
      ],
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: widget.showAppBar
          ? Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                title: const Text(
                  'العناصر والمنتجات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: FilledButton.icon(
                      onPressed: () => _navigateToAddEdit(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة عنصر'),
                    ),
                  ),
                ],
              ),
              body: content,
            )
          : content,
    );
  }

  Widget _buildBody(List<ItemEntity> filtered, bool isFiltered) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.error, fontSize: 14),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return ItemsEmptyState(
        isFiltered: isFiltered,
        onAddItem: () => _navigateToAddEdit(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth > 700) {
            crossAxisCount = 2;
          }

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 250,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              return ItemCard(
                item: item,
                margin: EdgeInsets.zero,
                departmentName: _getDepartmentName(item.effectiveDepartmentId),
                categoryPath: _getCategoryPath(item.effectiveCategoryId),
                baseUnitName: _baseUnits[item.id],
                onTap: () => _showItemDetails(item),
                onEdit: () => _navigateToAddEdit(item: item),
                onDelete: () => _deleteItem(item),
              );
            },
          );
        },
      ),
    );
  }
}

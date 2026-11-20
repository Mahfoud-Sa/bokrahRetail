import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/items/data/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/items/data/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/items/data/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/data/services/categories_service.dart';
import 'package:bokrah_retail/app/features/items/data/services/departments_service.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/features/units/data/datasources/unit_local_datasource.dart';
import 'package:bokrah_retail/app/features/units/data/repositories/unit_repository_impl.dart';
import 'package:bokrah_retail/app/features/units/domain/usecases/unit_usecases.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';

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
  final DepartmentsService _departmentsService = DepartmentsService();
  final CategoriesService _categoriesService = CategoriesService();
  final TextEditingController _searchController = TextEditingController();

  List<ItemEntity> _items = [];
  List<DepartmentEntity> _departments = [];
  List<CategoryEntity> _categories = [];
  Map<int, String> _baseUnits = {};
  bool _isLoading = true;

  String _searchQuery = '';
  ItemUsageStatus? _selectedStatusFilter; // null means "All"
  int? _selectedDepartmentFilter;
  int? _selectedCategoryFilter;

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
    setState(() => _isLoading = true);
    final allItems = await _itemsService.getAllItems();
    final departments = await _departmentsService.getAllDepartments();
    final categories = await _categoriesService.getAllCategories();

    final prefs = await SharedPreferences.getInstance();
    final unitDataSource = UnitLocalDataSourceImpl(sharedPreferences: prefs);
    final unitRepo = UnitRepositoryImpl(localDataSource: unitDataSource);
    final getAllUnits = GetAllUnitsUseCase(unitRepo);

    final allUnits = await getAllUnits();

    final baseUnitsMap = <int, String>{};
    for (var unit in allUnits) {
      if (unit.factor == 1.0) {
        baseUnitsMap[unit.itemId] = unit.name;
      }
    }

    setState(() {
      _items = allItems;
      _departments = departments;
      _categories = categories;
      _baseUnits = baseUnitsMap;
      _isLoading = false;
    });
  }

  List<ItemEntity> get _filteredItems {
    return _items.where((item) {
      // 1. Department filter (One-to-Many)
      if (_selectedDepartmentFilter != null &&
          item.effectiveDepartmentId != _selectedDepartmentFilter) {
        return false;
      }

      // 2. Category Tree filter (Self-joining hierarchy: includes sub-categories!)
      if (_selectedCategoryFilter != null) {
        final descendantIds = _categoriesService.getDescendantIds(
          _selectedCategoryFilter!,
          _categories,
        );
        final matchCategoryIds = {_selectedCategoryFilter!, ...descendantIds};
        if (item.effectiveCategoryId == null ||
            !matchCategoryIds.contains(item.effectiveCategoryId)) {
          return false;
        }
      }

      // 3. Usage Status filter
      if (_selectedStatusFilter != null &&
          item.usageStatus != _selectedStatusFilter) {
        return false;
      }

      // 4. Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final nameMatch = item.name.toLowerCase().contains(q);
        final subnameMatch =
            item.effectiveSubname?.toLowerCase().contains(q) ?? false;
        final brandMatch = item.brand?.toLowerCase().contains(q) ?? false;
        final companyMatch =
            item.effectiveCompany?.toLowerCase().contains(q) ?? false;
        final shortDescMatch =
            item.shortDescription?.toLowerCase().contains(q) ?? false;
        final fullDescMatch =
            item.effectiveFullDescription?.toLowerCase().contains(q) ?? false;
        final barcodeMatch =
            item.barcodes.any((b) => b.toLowerCase().contains(q));
        final deptMatch = item.effectiveDepartmentId != null &&
            _getDepartmentName(item.effectiveDepartmentId)
                .toLowerCase()
                .contains(q);
        final catMatch = item.effectiveCategoryId != null &&
            _getCategoryPath(item.effectiveCategoryId)
                .toLowerCase()
                .contains(q);

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
    final dynamic extraData = item ??
        ((_selectedDepartmentFilter != null || _selectedCategoryFilter != null)
            ? {
                'departmentId': _selectedDepartmentFilter,
                'categoryId': _selectedCategoryFilter,
              }
            : null);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف "${item.name}" نهائياً من النظام؟'),
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

  String _getDepartmentName(int? departmentId) {
    if (departmentId == null) return 'بدون قسم';
    try {
      return _departments.firstWhere((d) => d.id == departmentId).name;
    } catch (_) {
      return 'بدون قسم';
    }
  }

  String _getCategoryPath(int? categoryId) {
    if (categoryId == null) return 'بدون فئة';
    return _categoriesService.getCategoryPath(categoryId, _categories);
  }

  void _showItemDetails(ItemEntity item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Top Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepCobalt,
                            ),
                          ),
                          if (item.effectiveSubname != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.effectiveSubname!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildStatusBadge(item.usageStatus),
                  ],
                ),
                const SizedBox(height: 16),

                // Image Gallery
                _buildGallerySection(item),
                const SizedBox(height: 20),

                // Video Action if present
                if (item.video != null && item.video!.trim().isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.actionBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.actionBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill,
                          color: AppTheme.actionBlue,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'يوجد فيديو توضيحي للعنصر',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'اضغط لمشاهدة الفيديو عبر الرابط المرفق',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            final uri = Uri.tryParse(item.video!.trim());
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('فتح'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Metadata Cards Grid: Department, Category Tree, Brand, Company, Year
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (item.effectiveDepartmentId != null)
                      _buildInfoPill(
                        'القسم',
                        _getDepartmentName(item.effectiveDepartmentId),
                        Icons.apartment_outlined,
                      ),
                    if (item.effectiveCategoryId != null)
                      _buildInfoPill(
                        'الفئة',
                        _getCategoryPath(item.effectiveCategoryId),
                        Icons.account_tree_outlined,
                      ),
                    if (item.brand != null && item.brand!.isNotEmpty)
                      _buildInfoPill(
                        'العلامة التجارية',
                        item.brand!,
                        Icons.branding_watermark_outlined,
                      ),
                    if (item.effectiveCompany != null &&
                        item.effectiveCompany!.isNotEmpty)
                      _buildInfoPill(
                        'الشركة',
                        item.effectiveCompany!,
                        Icons.business,
                      ),
                    if (item.manufactureYear != null)
                      _buildInfoPill(
                        'سنة الصنع',
                        item.manufactureYear.toString(),
                        Icons.calendar_today_outlined,
                      ),
                    if (item.color != null && item.color!.isNotEmpty)
                      _buildInfoPill('اللون', item.color!, Icons.palette_outlined),
                    if (item.size != null && item.size!.isNotEmpty)
                      _buildInfoPill(
                        'المقاس',
                        item.size!,
                        Icons.aspect_ratio_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Short Description
                if (item.shortDescription != null &&
                    item.shortDescription!.isNotEmpty) ...[
                  const Text(
                    'الوصف المختصر',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.deepCobalt,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.shortDescription!,
                      style: TextStyle(color: Colors.grey[800], fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Full Description
                if (item.effectiveFullDescription != null &&
                    item.effectiveFullDescription!.isNotEmpty) ...[
                  const Text(
                    'الوصف الكامل والمواصفات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.deepCobalt,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      item.effectiveFullDescription!,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Financial & Inventory Overview
                Card(
                  elevation: 0,
                  color: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'التسعير والمخزون',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              'سعر الشراء',
                              '${item.purchasePrice.toStringAsFixed(2)} ر.س',
                              AppTheme.warmOrange,
                            ),
                            _buildStatColumn(
                              'سعر البيع',
                              '${item.sellPrice.toStringAsFixed(2)} ر.س',
                              AppTheme.success,
                            ),
                            _buildStatColumn(
                              'هامش الربح',
                              '${item.profitMargin.toStringAsFixed(2)} ر.س',
                              item.profitMargin >= 0
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                            _buildStatColumn(
                              'الكمية المتوفرة',
                              '${item.quantity} ${_baseUnits[item.id] ?? ''}',
                              AppTheme.deepCobalt,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToAddEdit(item: item);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('تعديل البيانات'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteItem(item);
                      },
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                      tooltip: 'حذف العنصر',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGallerySection(ItemEntity item) {
    final allImages = <String>[];
    if (item.effectiveMainImage != null &&
        item.effectiveMainImage!.trim().isNotEmpty) {
      allImages.add(item.effectiveMainImage!.trim());
    }
    for (final img in item.effectiveSubImages) {
      if (img.trim().isNotEmpty && !allImages.contains(img.trim())) {
        allImages.add(img.trim());
      }
    }

    if (allImages.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 6),
              Text(
                'لم يتم رفع صور لهذا العنصر',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allImages.length,
        itemBuilder: (context, index) {
          final isMain = index == 0 && item.effectiveMainImage != null;
          return Container(
            width: 150,
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isMain ? AppTheme.actionBlue : AppTheme.border,
                width: isMain ? 2 : 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    allImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                if (isMain)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.actionBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'رئيسية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.actionBlue),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepCobalt,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ItemUsageStatus status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${status.labelAr} (${status.value})',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ItemUsageStatus status) {
    return switch (status) {
      ItemUsageStatus.newItem => AppTheme.success,
      ItemUsageStatus.second => AppTheme.warmOrange,
      ItemUsageStatus.used => Colors.blueGrey,
      ItemUsageStatus.openBox => AppTheme.actionBlue,
    };
  }

  IconData _getStatusIcon(ItemUsageStatus status) {
    return switch (status) {
      ItemUsageStatus.newItem => Icons.fiber_new_rounded,
      ItemUsageStatus.second => Icons.restart_alt_rounded,
      ItemUsageStatus.used => Icons.history_rounded,
      ItemUsageStatus.openBox => Icons.inventory_2_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    final content = Column(
      children: [
        // Top Filter Bar (Search + Department Filter + Category Tree Filter + Status Filter)
        _buildFilterHeader(),

        // Items List or Empty View
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
                      final item = filtered[index];
                      return _buildItemCard(item);
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

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.7)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search row with Add button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText:
                        'البحث بالاسم، القسم، الفئة، الماركة، أو الباركود...',
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
              if (!widget.showAppBar) ...[
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _navigateToAddEdit(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة عنصر'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Filters Row: Department dropdown + Category Tree dropdown + Status chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. Department filter (One-to-Many)
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: _selectedDepartmentFilter != null
                        ? AppTheme.actionBlue.withValues(alpha: 0.12)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedDepartmentFilter != null
                          ? AppTheme.actionBlue
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedDepartmentFilter,
                      hint: const Row(
                        children: [
                          Icon(Icons.apartment_outlined, size: 14),
                          SizedBox(width: 6),
                          Text('جميع الأقسام', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      isDense: true,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'جميع الأقسام',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._departments.map((d) {
                          return DropdownMenuItem<int?>(
                            value: d.id,
                            child: Text(
                              d.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedDepartmentFilter = val);
                      },
                    ),
                  ),
                ),

                // 2. Category Tree filter (Self-joining hierarchy)
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: _selectedCategoryFilter != null
                        ? AppTheme.actionBlue.withValues(alpha: 0.12)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedCategoryFilter != null
                          ? AppTheme.actionBlue
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedCategoryFilter,
                      hint: const Row(
                        children: [
                          Icon(Icons.account_tree_outlined, size: 14),
                          SizedBox(width: 6),
                          Text('شجرة الفئات', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      isDense: true,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'جميع الفئات',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._categories.map((c) {
                          return DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(
                              _categoriesService.getCategoryPath(
                                c.id!,
                                _categories,
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedCategoryFilter = val);
                      },
                    ),
                  ),
                ),

                // 3. Status Filter Chips
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: FilterChip(
                    label: Text(
                      'الكل (${_items.length})',
                      style: TextStyle(
                        fontWeight: _selectedStatusFilter == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: _selectedStatusFilter == null,
                    onSelected: (_) =>
                        setState(() => _selectedStatusFilter = null),
                  ),
                ),
                ...ItemUsageStatus.values.map((status) {
                  final isSelected = _selectedStatusFilter == status;
                  final count =
                      _items.where((i) => i.usageStatus == status).length;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      avatar: Icon(
                        _getStatusIcon(status),
                        size: 14,
                        color: isSelected
                            ? Colors.white
                            : _getStatusColor(status),
                      ),
                      label: Text(
                        '${status.labelAr} ($count)',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: _getStatusColor(status),
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatusFilter = selected ? status : null;
                        });
                      },
                    ),
                  );
                }),
              ],
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
            Icons.inventory_2_outlined,
            size: 72,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ||
                    _selectedStatusFilter != null ||
                    _selectedDepartmentFilter != null ||
                    _selectedCategoryFilter != null
                ? 'لا توجد نتائج مطابقة لمعايير البحث'
                : 'لا توجد عناصر مضافة في النظام بعد',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ||
                    _selectedStatusFilter != null ||
                    _selectedDepartmentFilter != null ||
                    _selectedCategoryFilter != null
                ? 'جرّب تغيير كلمات البحث أو إلغاء فلاتر التصفية'
                : 'اضغط على زر "إضافة عنصر" للبدء بإضافة أول منتج للمتجر',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddEdit(),
            icon: const Icon(Icons.add),
            label: const Text('إضافة عنصر جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemEntity item) {
    final hasMainImage = item.effectiveMainImage != null &&
        item.effectiveMainImage!.trim().isNotEmpty;
    final subImagesCount = item.effectiveSubImages.length;
    final hasVideo = item.video != null && item.video!.trim().isNotEmpty;
    final deptName = _getDepartmentName(item.effectiveDepartmentId);
    final catPath = _getCategoryPath(item.effectiveCategoryId);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: () => _showItemDetails(item),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Image + Name + Status + Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image / Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: hasMainImage ? Colors.transparent : Colors.grey[200],
                      child: hasMainImage
                          ? Image.network(
                              item.effectiveMainImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildFallbackAvatar(item),
                            )
                          : _buildFallbackAvatar(item),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and Subname
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.deepCobalt,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(item.usageStatus),
                          ],
                        ),
                        if (item.effectiveSubname != null &&
                            item.effectiveSubname!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.effectiveSubname!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Popup Menu
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view') {
                        _showItemDetails(item);
                      } else if (value == 'edit') {
                        _navigateToAddEdit(item: item);
                      } else if (value == 'delete') {
                        _deleteItem(item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('عرض التفاصيل'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: AppTheme.actionBlue),
                            SizedBox(width: 8),
                            Text('تعديل'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppTheme.error),
                            SizedBox(width: 8),
                            Text('حذف'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Badges row: Department, Category Tree, Brand, Company, Year
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (item.effectiveDepartmentId != null)
                    _buildTagChip(
                      deptName,
                      Icons.apartment_outlined,
                      color: AppTheme.actionBlue,
                    ),
                  if (item.effectiveCategoryId != null)
                    _buildTagChip(
                      catPath,
                      Icons.account_tree_outlined,
                      color: AppTheme.deepCobalt,
                    ),
                  if (item.brand != null && item.brand!.isNotEmpty)
                    _buildTagChip(item.brand!, Icons.branding_watermark_outlined),
                  if (item.effectiveCompany != null &&
                      item.effectiveCompany!.isNotEmpty)
                    _buildTagChip(item.effectiveCompany!, Icons.business),
                  if (item.manufactureYear != null)
                    _buildTagChip(
                      'سنة: ${item.manufactureYear}',
                      Icons.calendar_today_outlined,
                    ),
                  if (subImagesCount > 0)
                    _buildTagChip(
                      '+$subImagesCount صور',
                      Icons.photo_library_outlined,
                    ),
                  if (hasVideo)
                    _buildTagChip(
                      'فيديو',
                      Icons.videocam_outlined,
                      color: AppTheme.actionBlue,
                    ),
                ],
              ),

              // Short Description
              if (item.shortDescription != null &&
                  item.shortDescription!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.shortDescription!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const Divider(height: 16),

              // Bottom Stats Row: Prices, Stock, Margin
              Row(
                children: [
                  // Buy Price
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 15,
                    color: AppTheme.warmOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'شراء: ${item.purchasePrice.toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Sell Price
                  const Icon(Icons.attach_money, size: 15, color: AppTheme.success),
                  const SizedBox(width: 2),
                  Text(
                    'بيع: ${item.sellPrice.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepCobalt,
                    ),
                  ),
                  const Spacer(),

                  // Stock Quantity
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 15,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'الكمية: ${item.quantity} ${_baseUnits[item.id] ?? ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(ItemEntity item) {
    return Container(
      color: AppTheme.actionBlue.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          item.name.isNotEmpty ? item.name[0] : '؟',
          style: const TextStyle(
            color: AppTheme.actionBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(
    String label,
    IconData icon, {
    Color? color,
  }) {
    final effectiveColor = color ?? Colors.grey[700]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:bokrah_retail/app/features/items/data/entities/category_entity.dart';
import 'package:bokrah_retail/app/features/items/data/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/data/services/categories_service.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/features/units/data/datasources/unit_local_datasource.dart';
import 'package:bokrah_retail/app/features/units/data/repositories/unit_repository_impl.dart';
import 'package:bokrah_retail/app/features/units/domain/usecases/unit_usecases.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';

class ItemsPage extends StatefulWidget {
  final int? categoryId; // Added categoryId for filtering
  const ItemsPage({super.key, this.categoryId});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final ItemsService _itemsService = ItemsService();
  final CategoriesService _categoriesService = CategoriesService();

  List<ItemEntity> _items = [];
  List<CategoryEntity> _categories = [];
  Map<int, String> _baseUnits = {}; // Map itemId to base unit name
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allItems = await _itemsService.getAllItems();
    final categories = await _categoriesService.getAllCategories();

    final prefs = await SharedPreferences.getInstance();
    final unitDataSource = UnitLocalDataSourceImpl(sharedPreferences: prefs);
    final unitRepo = UnitRepositoryImpl(localDataSource: unitDataSource);
    final getAllUnits = GetAllUnitsUseCase(unitRepo);

    final allUnits = await getAllUnits();

    // Map base units (factor 1.0) to item ids
    final baseUnitsMap = <int, String>{};
    for (var unit in allUnits) {
      if (unit.factor == 1.0) {
        baseUnitsMap[unit.itemId] = unit.name;
      }
    }

    // Filter items if categoryId is provided
    final items = widget.categoryId != null
        ? allItems
              .where((item) => item.categoryId == widget.categoryId)
              .toList()
        : allItems;

    setState(() {
      _items = items;
      _categories = categories;
      _baseUnits = baseUnitsMap;
      _isLoading = false;
    });
  }

  Future<void> _navigateToAddEdit({ItemEntity? item}) async {
    if (!await AppAccessGuard.requireRestaurant(
      context: context,
      returnRoute: '/items',
    )) {
      return;
    }
    final result = await context.push<bool>('/add-item', extra: item);
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteItem(ItemEntity item) async {
    if (!await AppAccessGuard.requireRestaurant(
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
          content: Text('هل أنت متأكد من حذف "${item.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && item.id != null) {
      final success = await _itemsService.deleteItem(item.id!);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف العنصر بنجاح'),
            backgroundColor: Color(0xFF2E7D64),
          ),
        );
        _loadData();
      }
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
            'العناصر',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2E7D64),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToAddEdit(),
              tooltip: 'إضافة عنصر جديد',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد عناصر',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اضغط على + لإضافة عنصر جديد',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddEdit(),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة عنصر'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D64),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2E7D64),
                          child: Text(
                            item.name.isNotEmpty ? item.name[0] : '؟',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (item.categoryId != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2E7D64,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _categories
                                      .firstWhere(
                                        (c) => c.id == item.categoryId,
                                        orElse: () =>
                                            CategoryEntity(name: '...'),
                                      )
                                      .name,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF2E7D64),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            // Purchase and Sell Prices Row
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  size: 16,
                                  color: Colors.orange[600],
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'شراء: ${item.purchasePrice.toStringAsFixed(2)} ر.س',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.attach_money,
                                  size: 16,
                                  color: Colors.green[600],
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'بيع: ${item.sellPrice.toStringAsFixed(2)} ر.س',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Quantity and Profit Row
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'الكمية: ${item.quantity} ${_baseUnits[item.id] ?? ''}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.trending_up,
                                  size: 16,
                                  color: item.profitMargin >= 0
                                      ? Colors.green[600]
                                      : Colors.red[600],
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'ربح: ${item.profitMargin.toStringAsFixed(2)} ر.س',
                                    style: TextStyle(
                                      color: item.profitMargin >= 0
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (item.qrCode != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.qrCode!,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (item.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.description!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _navigateToAddEdit(item: item);
                            } else if (value == 'delete') {
                              _deleteItem(item);
                            }
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
          onPressed: () => _navigateToAddEdit(),
          backgroundColor: const Color(0xFF2E7D64),
          tooltip: 'إضافة عنصر جديد',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

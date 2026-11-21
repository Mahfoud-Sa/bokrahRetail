import 'dart:convert';
import 'package:bokrah_retail/app/features/items/data/models/item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ItemsLocalDataSource {
  Future<List<ItemModel>> getAllItems();
  Future<ItemModel?> getItemById(int id);
  Future<ItemModel?> saveItem(ItemModel item);
  Future<bool> updateItem(ItemModel item);
  Future<bool> deleteItem(int id);
}

class ItemsLocalDataSourceImpl implements ItemsLocalDataSource {
  static const String _itemsKey = 'items_list';
  final SharedPreferences? _prefs;

  ItemsLocalDataSourceImpl({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ?? await SharedPreferences.getInstance();

  @override
  Future<List<ItemModel>> getAllItems() async {
    final prefs = await _instance;
    final itemsJson = prefs.getStringList(_itemsKey) ?? [];

    return itemsJson.map((jsonString) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return ItemModel.fromMap(map);
    }).toList();
  }

  @override
  Future<ItemModel?> getItemById(int id) async {
    final items = await getAllItems();
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ItemModel?> saveItem(ItemModel item) async {
    try {
      final prefs = await _instance;
      final items = await getAllItems();

      final newItem = item.id != null
          ? item
          : ItemModel(
              id: DateTime.now().millisecondsSinceEpoch,
              name: item.name,
              subname: item.subname,
              popularName: item.popularName,
              usageStatus: item.usageStatus,
              mainImage: item.mainImage,
              baseImage: item.baseImage,
              subImages: item.subImages,
              images: item.images,
              video: item.video,
              company: item.company,
              companyName: item.companyName,
              brand: item.brand,
              manufactureYear: item.manufactureYear,
              shortDescription: item.shortDescription,
              fullDescription: item.fullDescription,
              description: item.description,
              color: item.color,
              size: item.size,
              barcodes: item.barcodes,
              sellPrice: item.sellPrice,
              purchasePrice: item.purchasePrice,
              quantity: item.quantity,
              qrCode: item.qrCode,
              departmentId: item.departmentId,
              categoryId: item.categoryId,
              createdAt: item.createdAt,
            );

      items.add(newItem);

      final itemsJson = items.map((i) => json.encode(i.toMap())).toList();
      await prefs.setStringList(_itemsKey, itemsJson);

      return newItem;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> updateItem(ItemModel item) async {
    try {
      final prefs = await _instance;
      final items = await getAllItems();

      final index = items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        items[index] = item;

        final itemsJson = items.map((i) => json.encode(i.toMap())).toList();
        await prefs.setStringList(_itemsKey, itemsJson);

        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteItem(int id) async {
    try {
      final prefs = await _instance;
      final items = await getAllItems();

      items.removeWhere((item) => item.id == id);

      final itemsJson = items.map((i) => json.encode(i.toMap())).toList();
      await prefs.setStringList(_itemsKey, itemsJson);

      return true;
    } catch (_) {
      return false;
    }
  }
}

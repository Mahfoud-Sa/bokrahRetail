import 'dart:convert';
import 'package:bokrah_retail/app/features/items/data/entities/item_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemsService {
  static const String _itemsKey = 'items_list';

  Future<List<ItemEntity>> getAllItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getStringList(_itemsKey) ?? [];

    return itemsJson.map((jsonString) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return ItemEntity.fromMap(map);
    }).toList();
  }

  Future<ItemEntity?> saveItem(ItemEntity item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getAllItems();

      // Generate a simple ID if not provided
      final newItem = ItemEntity(
        id: item.id ?? DateTime.now().millisecondsSinceEpoch,
        name: item.name,
        popularName: item.popularName,
        images: item.images,
        baseImage: item.baseImage,
        companyName: item.companyName,
        color: item.color,
        size: item.size,
        barcodes: item.barcodes,
        sellPrice: item.sellPrice,
        purchasePrice: item.purchasePrice,
        quantity: item.quantity,
        qrCode: item.qrCode,
        description: item.description,
        categoryId: item.categoryId,
        createdAt: item.createdAt,
      );

      items.add(newItem);

      final itemsJson = items.map((item) => json.encode(item.toMap())).toList();
      await prefs.setStringList(_itemsKey, itemsJson);

      return newItem;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateItem(ItemEntity item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getAllItems();

      final index = items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        items[index] = item;

        final itemsJson = items
            .map((item) => json.encode(item.toMap()))
            .toList();
        await prefs.setStringList(_itemsKey, itemsJson);

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteItem(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getAllItems();

      items.removeWhere((item) => item.id == id);

      final itemsJson = items.map((item) => json.encode(item.toMap())).toList();
      await prefs.setStringList(_itemsKey, itemsJson);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<ItemEntity?> getItemById(int id) async {
    final items = await getAllItems();
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}

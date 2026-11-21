import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';

abstract class ItemsRepository {
  Future<List<ItemEntity>> getAllItems();
  Future<ItemEntity?> getItemById(int id);
  Future<ItemEntity?> saveItem(ItemEntity item);
  Future<bool> updateItem(ItemEntity item);
  Future<bool> deleteItem(int id);
}

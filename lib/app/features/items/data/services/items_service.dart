import 'package:bokrah_retail/app/features/items/data/repositories/items_repository_impl.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/repositories/items_repository.dart';

class ItemsService {
  final ItemsRepository _repository;

  ItemsService({ItemsRepository? repository})
      : _repository = repository ?? ItemsRepositoryImpl();

  Future<List<ItemEntity>> getAllItems() => _repository.getAllItems();
  Future<ItemEntity?> saveItem(ItemEntity item) => _repository.saveItem(item);
  Future<bool> updateItem(ItemEntity item) => _repository.updateItem(item);
  Future<bool> deleteItem(int id) => _repository.deleteItem(id);
  Future<ItemEntity?> getItemById(int id) => _repository.getItemById(id);
}

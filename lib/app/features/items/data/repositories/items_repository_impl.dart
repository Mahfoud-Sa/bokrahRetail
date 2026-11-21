import 'package:bokrah_retail/app/features/items/data/datasources/items_local_datasource.dart';
import 'package:bokrah_retail/app/features/items/data/models/item_model.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/repositories/items_repository.dart';

class ItemsRepositoryImpl implements ItemsRepository {
  final ItemsLocalDataSource localDataSource;

  ItemsRepositoryImpl({ItemsLocalDataSource? localDataSource})
      : localDataSource = localDataSource ?? ItemsLocalDataSourceImpl();

  @override
  Future<List<ItemEntity>> getAllItems() async {
    return await localDataSource.getAllItems();
  }

  @override
  Future<ItemEntity?> getItemById(int id) async {
    return await localDataSource.getItemById(id);
  }

  @override
  Future<ItemEntity?> saveItem(ItemEntity item) async {
    final model = ItemModel.fromEntity(item);
    return await localDataSource.saveItem(model);
  }

  @override
  Future<bool> updateItem(ItemEntity item) async {
    final model = ItemModel.fromEntity(item);
    return await localDataSource.updateItem(model);
  }

  @override
  Future<bool> deleteItem(int id) async {
    return await localDataSource.deleteItem(id);
  }
}

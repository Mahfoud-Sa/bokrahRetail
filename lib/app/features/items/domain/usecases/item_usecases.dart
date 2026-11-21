import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/repositories/items_repository.dart';

class GetAllItemsUseCase {
  final ItemsRepository repository;
  GetAllItemsUseCase(this.repository);

  Future<List<ItemEntity>> call() async {
    return await repository.getAllItems();
  }
}

class GetItemByIdUseCase {
  final ItemsRepository repository;
  GetItemByIdUseCase(this.repository);

  Future<ItemEntity?> call(int id) async {
    return await repository.getItemById(id);
  }
}

class SaveItemUseCase {
  final ItemsRepository repository;
  SaveItemUseCase(this.repository);

  Future<ItemEntity?> call(ItemEntity item) async {
    return await repository.saveItem(item);
  }
}

class UpdateItemUseCase {
  final ItemsRepository repository;
  UpdateItemUseCase(this.repository);

  Future<bool> call(ItemEntity item) async {
    return await repository.updateItem(item);
  }
}

class DeleteItemUseCase {
  final ItemsRepository repository;
  DeleteItemUseCase(this.repository);

  Future<bool> call(int id) async {
    return await repository.deleteItem(id);
  }
}

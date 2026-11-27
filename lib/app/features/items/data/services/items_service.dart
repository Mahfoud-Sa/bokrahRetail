import 'package:bokrah_retail/app/features/barcoders/data/services/barcodes_service.dart';
import 'package:bokrah_retail/app/features/items/data/repositories/items_repository_impl.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/repositories/items_repository.dart';

class ItemsService {
  final ItemsRepository _repository;
  final BarcodesService _barcodesService;

  ItemsService({ItemsRepository? repository, BarcodesService? barcodesService})
    : _repository = repository ?? ItemsRepositoryImpl(),
      _barcodesService = barcodesService ?? BarcodesService();

  Future<List<ItemEntity>> getAllItems() => _repository.getAllItems();
  Future<ItemEntity?> saveItem(ItemEntity item) => _repository.saveItem(item);
  Future<bool> updateItem(ItemEntity item) => _repository.updateItem(item);

  Future<bool> deleteItem(int id) async {
    final deleted = await _repository.deleteItem(id);
    if (deleted) {
      await _barcodesService.unlinkAllBarcodesForItem(id);
    }
    return deleted;
  }

  Future<ItemEntity?> getItemById(int id) => _repository.getItemById(id);
}

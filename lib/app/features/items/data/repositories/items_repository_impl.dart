import 'package:bokrah_retail/app/features/items/data/datasources/items_local_datasource.dart';
import 'package:bokrah_retail/app/features/items/data/models/item_model.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/repositories/items_repository.dart';
import 'package:bokrah_retail/app/features/sync/data/services/sync_outbox_recorder.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';

class ItemsRepositoryImpl implements ItemsRepository {
  final ItemsLocalDataSource localDataSource;
  final SyncOutboxRecorder _outboxRecorder;

  ItemsRepositoryImpl({
    ItemsLocalDataSource? localDataSource,
    SyncOutboxRecorder? outboxRecorder,
  })  : localDataSource = localDataSource ?? ItemsLocalDataSourceImpl(),
        _outboxRecorder = outboxRecorder ?? SyncOutboxRecorder();

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
    final saved = await localDataSource.saveItem(model);
    if (saved != null && saved.id != null) {
      await _outboxRecorder.record(
        entityType: SyncEntityType.item,
        operationType: SyncOperationType.create,
        localEntityId: saved.id!,
        payload: ItemModel.fromEntity(saved).toMap(),
      );
    }
    return saved;
  }

  @override
  Future<bool> updateItem(ItemEntity item) async {
    final model = ItemModel.fromEntity(item);
    final ok = await localDataSource.updateItem(model);
    if (ok && item.id != null) {
      await _outboxRecorder.record(
        entityType: SyncEntityType.item,
        operationType: SyncOperationType.update,
        localEntityId: item.id!,
        payload: model.toMap(),
      );
    }
    return ok;
  }

  @override
  Future<bool> deleteItem(int id) async {
    final ok = await localDataSource.deleteItem(id);
    if (ok) {
      await _outboxRecorder.record(
        entityType: SyncEntityType.item,
        operationType: SyncOperationType.delete,
        localEntityId: id,
      );
    }
    return ok;
  }
}

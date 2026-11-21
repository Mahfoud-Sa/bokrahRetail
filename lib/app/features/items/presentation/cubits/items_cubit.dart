import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/usecases/item_usecases.dart';
import 'package:bokrah_retail/app/features/items/presentation/cubits/items_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ItemsCubit extends Cubit<ItemsState> {
  final GetAllItemsUseCase getAllItemsUseCase;
  final GetItemByIdUseCase getItemByIdUseCase;
  final SaveItemUseCase saveItemUseCase;
  final UpdateItemUseCase updateItemUseCase;
  final DeleteItemUseCase deleteItemUseCase;

  ItemsCubit({
    required this.getAllItemsUseCase,
    required this.getItemByIdUseCase,
    required this.saveItemUseCase,
    required this.updateItemUseCase,
    required this.deleteItemUseCase,
  }) : super(ItemsInitial());

  Future<void> loadAllItems() async {
    emit(ItemsLoading());
    try {
      final items = await getAllItemsUseCase();
      emit(ItemsLoaded(items));
    } catch (e) {
      emit(ItemsError(e.toString()));
    }
  }

  Future<ItemEntity?> saveItem(ItemEntity item) async {
    try {
      final savedItem = await saveItemUseCase(item);
      if (savedItem != null) {
        await loadAllItems();
        return savedItem;
      } else {
        emit(const ItemsError('فشل حفظ العنصر'));
        return null;
      }
    } catch (e) {
      emit(ItemsError(e.toString()));
      return null;
    }
  }

  Future<bool> updateItem(ItemEntity item) async {
    try {
      final success = await updateItemUseCase(item);
      if (success) {
        await loadAllItems();
        return true;
      } else {
        emit(const ItemsError('فشل تحديث العنصر'));
        return false;
      }
    } catch (e) {
      emit(ItemsError(e.toString()));
      return false;
    }
  }

  Future<bool> deleteItem(int id) async {
    try {
      final success = await deleteItemUseCase(id);
      if (success) {
        await loadAllItems();
        return true;
      } else {
        emit(const ItemsError('فشل حذف العنصر'));
        return false;
      }
    } catch (e) {
      emit(ItemsError(e.toString()));
      return false;
    }
  }
}

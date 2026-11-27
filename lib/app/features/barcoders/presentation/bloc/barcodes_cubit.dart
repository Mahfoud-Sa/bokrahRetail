import 'package:bokrah_retail/app/features/barcoders/data/repository/barcode_repository_imp.dart';
import 'package:bokrah_retail/app/features/barcoders/domain/entities/barcode_entity.dart';
import 'package:bokrah_retail/app/features/barcoders/domain/repository/barcode_repository.dart';
import 'package:bokrah_retail/app/features/barcoders/presentation/bloc/barcodes_state.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BarcodesCubit extends Cubit<BarcodesState> {
  final BarcodeRepository _repository;
  final ItemsService _itemsService;

  BarcodesCubit({BarcodeRepository? repository, ItemsService? itemsService})
    : _repository = repository ?? BarcodeRepositoryImpl(),
      _itemsService = itemsService ?? ItemsService(),
      super(const BarcodesState());

  Future<void> loadBarcodes() async {
    emit(state.copyWith(status: BarcodesStatus.loading, clearError: true));
    try {
      final barcodes = await _repository.getAllBarcodes();
      final allItems = await _itemsService.getAllItems();
      final allLinks = await _repository.getAllLinks();

      final relatedItems = <int, List<ItemEntity>>{};
      for (final barcode in barcodes) {
        if (barcode.id == null) continue;
        final itemIds = allLinks
            .where((l) => l.barcodeId == barcode.id)
            .map((l) => l.itemId)
            .toSet();
        relatedItems[barcode.id!] = allItems
            .where((it) => itemIds.contains(it.id))
            .toList();
      }

      emit(
        state.copyWith(
          status: BarcodesStatus.loaded,
          barcodes: barcodes,
          allItems: allItems,
          relatedItems: relatedItems,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BarcodesStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<bool> saveBarcode(BarcodeEntity barcode) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final success = await _repository.saveBarcode(barcode);
      emit(state.copyWith(isSaving: false));
      if (success) {
        await loadBarcodes();
      }
      return success;
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
      return false;
    }
  }

  Future<bool> updateBarcode(BarcodeEntity barcode) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final success = await _repository.updateBarcode(barcode);
      emit(state.copyWith(isSaving: false));
      if (success) {
        await loadBarcodes();
      }
      return success;
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
      return false;
    }
  }

  Future<bool> deleteBarcode(int id) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final success = await _repository.deleteBarcode(id);
      emit(state.copyWith(isSaving: false));
      if (success) {
        await loadBarcodes();
      }
      return success;
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
      return false;
    }
  }

  Future<void> toggleItemLink({
    required int itemId,
    required int barcodeId,
    required bool link,
  }) async {
    try {
      if (link) {
        await _repository.linkItemToBarcode(itemId, barcodeId);
      } else {
        await _repository.unlinkItemFromBarcode(itemId, barcodeId);
      }
      await loadBarcodes();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}

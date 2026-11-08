import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/store_entity.dart';
import '../../data/services/store_service.dart';
import '../../data/services/store_api_service.dart';
import 'store_state.dart';

class StoreCubit extends Cubit<StoreState> {
  final StoreService service;
  final StoreApiService? apiService;

  StoreCubit({
    required this.service,
    this.apiService,
  }) : super(const StoreInitial());

  /// Currently active tenant store ID
  int? get activeStoreId {
    final st = state;
    return st is StoreLoaded ? st.activeStoreId : null;
  }

  /// Loads the primary active store and cached accessible stores
  Future<void> loadStore([String? userIdOrEmail]) async {
    emit(const StoreLoading());
    try {
      final info = await service.getStoreInfo();
      final hasRegistered = await service.hasRegisteredStore(userIdOrEmail);
      final activeId = await service.getActiveStoreId() ?? int.tryParse(info.id);
      final cachedStores = await service.getCachedAccessibleStores();

      emit(StoreLoaded(
        store: info,
        hasStore: hasRegistered,
        activeStoreId: activeId,
        accessibleStores: cachedStores.isNotEmpty ? cachedStores : [info],
      ));

      // Attempt background refresh of user's accessible stores
      if (apiService != null) {
        loadMyStores(silent: true);
      }
    } catch (e) {
      emit(StoreError('فشل في تحميل بيانات المتجر: ${e.toString()}'));
    }
  }

  /// Lists all accessible stores for current user via `GET /api/stores`
  /// and updates the multi-store switcher state.
  Future<void> loadMyStores({bool silent = false}) async {
    final currentState = state;
    if (apiService == null) return;

    if (!silent && currentState is StoreLoaded) {
      emit(currentState.copyWith(isLoadingStores: true));
    }

    try {
      final dtoList = await apiService!.getMyStores();
      final entities = dtoList.map((dto) => dto.toEntity()).toList();

      if (entities.isNotEmpty) {
        await service.cacheAccessibleStores(entities);
      }

      final currentActiveId = await service.getActiveStoreId();
      StoreEntity selectedStore;
      int selectedId;

      if (currentActiveId != null &&
          entities.any((s) => int.tryParse(s.id) == currentActiveId)) {
        selectedStore =
            entities.firstWhere((s) => int.tryParse(s.id) == currentActiveId);
        selectedId = currentActiveId;
      } else if (entities.isNotEmpty) {
        selectedStore = entities.first;
        selectedId = int.tryParse(selectedStore.id) ?? 1;
        await service.setActiveStoreId(selectedId);
      } else {
        selectedStore = currentState is StoreLoaded
            ? currentState.store
            : await service.getStoreInfo();
        selectedId = int.tryParse(selectedStore.id) ?? 1;
      }

      await service.updateStoreInfo(selectedStore);

      if (state is StoreLoaded) {
        final st = state as StoreLoaded;
        emit(st.copyWith(
          store: selectedStore,
          hasStore: true,
          activeStoreId: selectedId,
          accessibleStores: entities,
          isLoadingStores: false,
        ));
      } else {
        emit(StoreLoaded(
          store: selectedStore,
          hasStore: true,
          activeStoreId: selectedId,
          accessibleStores: entities,
          isLoadingStores: false,
        ));
      }
    } catch (_) {
      if (state is StoreLoaded) {
        emit((state as StoreLoaded).copyWith(isLoadingStores: false));
      }
    }
  }

  /// Switches active tenant context to [storeId]
  /// Scopes subsequent operations and updates persistent storage.
  Future<bool> switchActiveStore(int storeId) async {
    final currentState = state;
    if (currentState is! StoreLoaded) return false;

    emit(currentState.copyWith(isLoadingStores: true));

    try {
      StoreEntity targetStore;
      if (apiService != null) {
        try {
          final dto = await apiService!.getStoreById(storeId);
          targetStore = dto.toEntity();
        } catch (_) {
          targetStore = currentState.accessibleStores.firstWhere(
            (s) => int.tryParse(s.id) == storeId,
            orElse: () => currentState.store,
          );
        }
      } else {
        targetStore = currentState.accessibleStores.firstWhere(
          (s) => int.tryParse(s.id) == storeId,
          orElse: () => currentState.store,
        );
      }

      await service.setActiveStoreId(storeId);
      await service.updateStoreInfo(targetStore);

      emit(currentState.copyWith(
        store: targetStore,
        activeStoreId: storeId,
        isLoadingStores: false,
        successMessage: 'تم التبديل إلى متجر ${targetStore.nameAr.isNotEmpty ? targetStore.nameAr : targetStore.nameEn}',
      ));
      return true;
    } catch (e) {
      emit(currentState.copyWith(
        isLoadingStores: false,
        errorMessage: 'فشل في تبديل المتجر: ${e.toString()}',
      ));
      return false;
    }
  }

  void setHasStore(bool value, [String? userIdOrEmail]) {
    service.setHasRegisteredStore(value, userIdOrEmail);
    final currentState = state;
    if (currentState is StoreLoaded) {
      emit(currentState.copyWith(hasStore: value));
    }
  }

  Future<void> markStoreRegistered(StoreEntity info, [String? userIdOrEmail]) async {
    await service.setHasRegisteredStore(true, userIdOrEmail);
    await service.updateStoreInfo(info);
    final st = state;
    final currentStores = st is StoreLoaded ? st.accessibleStores : <StoreEntity>[];
    final updatedList = [
      info,
      ...currentStores.where((s) => s.id != info.id),
    ];
    final newId = int.tryParse(info.id);
    if (newId != null) {
      await service.setActiveStoreId(newId);
    }
    await service.cacheAccessibleStores(updatedList);

    emit(StoreLoaded(
      store: info,
      hasStore: true,
      activeStoreId: newId,
      accessibleStores: updatedList,
      successMessage:
          'تمت إضافة بيانات متجرك بنجاح. يمكنك الآن متابعة إدارة المخزون والمبيعات وكافة ميزات التجزئة.',
    ));
  }

  Future<bool> updateStore(StoreEntity updated, {bool? markRegistered}) async {
    final currentState = state;
    final shouldBeRegistered = markRegistered ??
        (currentState is StoreLoaded && currentState.hasStore);

    if (shouldBeRegistered) {
      await service.setHasRegisteredStore(true);
    }

    if (currentState is StoreLoaded) {
      emit(currentState.copyWith(isSaving: true, clearMessages: true));
      try {
        final success = await service.updateStoreInfo(updated);
        if (success) {
          final updatedStores = currentState.accessibleStores.map((s) {
            return s.id == updated.id ? updated : s;
          }).toList();
          await service.cacheAccessibleStores(updatedStores);

          emit(StoreLoaded(
            store: updated,
            hasStore: shouldBeRegistered,
            activeStoreId: currentState.activeStoreId,
            accessibleStores: updatedStores,
            isSaving: false,
            successMessage: 'تم حفظ وتحديث بيانات المتجر بنجاح',
          ));
          return true;
        } else {
          emit(currentState.copyWith(
            isSaving: false,
            errorMessage: 'فشل في حفظ البيانات، يُرجى المحاولة لاحقاً',
          ));
          return false;
        }
      } catch (e) {
        emit(currentState.copyWith(
          isSaving: false,
          errorMessage: 'حدث خطأ: ${e.toString()}',
        ));
        return false;
      }
    } else {
      final success = await service.updateStoreInfo(updated);
      if (success) {
        emit(StoreLoaded(
          store: updated,
          hasStore: shouldBeRegistered,
        ));
        return true;
      }
      return false;
    }
  }

  Future<void> resetDefaults() async {
    final currentState = state;
    if (currentState is StoreLoaded) {
      emit(currentState.copyWith(isSaving: true, clearMessages: true));
      try {
        final defaults = await service.resetToDefaults();
        emit(StoreLoaded(
          store: defaults,
          isSaving: false,
          hasStore: currentState.hasStore,
          activeStoreId: currentState.activeStoreId,
          accessibleStores: currentState.accessibleStores,
          successMessage: 'تمت استعادة الإعدادات الافتراضية للمتجر',
        ));
      } catch (e) {
        emit(currentState.copyWith(
          isSaving: false,
          errorMessage: 'فشل في استعادة الإعدادات الافتراضية: ${e.toString()}',
        ));
      }
    }
  }

  // --- Legacy Compatibility Methods ---
  Future<void> loadRestaurant([String? userIdOrEmail]) =>
      loadStore(userIdOrEmail);

  void setHasRestaurant(bool value, [String? userIdOrEmail]) =>
      setHasStore(value, userIdOrEmail);

  Future<void> markRestaurantRegistered(StoreEntity info,
          [String? userIdOrEmail]) =>
      markStoreRegistered(info, userIdOrEmail);

  Future<bool> updateRestaurant(StoreEntity updated, {bool? markRegistered}) =>
      updateStore(updated, markRegistered: markRegistered);
}

// Backward compatibility alias
typedef RestaurantCubit = StoreCubit;

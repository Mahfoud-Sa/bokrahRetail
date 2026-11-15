import 'package:equatable/equatable.dart';
import '../../data/models/store_entity.dart';

sealed class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object?> get props => [];
}

class StoreInitial extends StoreState {
  const StoreInitial();
}

class StoreLoading extends StoreState {
  const StoreLoading();
}

class StoreLoaded extends StoreState {
  final StoreEntity store;
  final bool hasStore;
  final bool isSaving;
  final bool isLoadingStores;
  final String? errorMessage;
  final String? successMessage;
  final List<StoreEntity> accessibleStores;
  final int? activeStoreId;

  const StoreLoaded({
    StoreEntity? store,
    bool? hasStore,
    this.isSaving = false,
    this.isLoadingStores = false,
    this.errorMessage,
    this.successMessage,
    this.accessibleStores = const [],
    this.activeStoreId,
  })  : store = store ?? const StoreEntity(nameAr: '', nameEn: ''),
        hasStore = hasStore ?? false;

  StoreEntity get activeStore => store;

  StoreLoaded copyWith({
    StoreEntity? store,
    bool? hasStore,
    bool? isSaving,
    bool? isLoadingStores,
    String? errorMessage,
    String? successMessage,
    List<StoreEntity>? accessibleStores,
    int? activeStoreId,
    bool clearMessages = false,
  }) {
    return StoreLoaded(
      store: store ?? this.store,
      hasStore: hasStore ?? this.hasStore,
      isSaving: isSaving ?? this.isSaving,
      isLoadingStores: isLoadingStores ?? this.isLoadingStores,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
      accessibleStores: accessibleStores ?? this.accessibleStores,
      activeStoreId: activeStoreId ?? this.activeStoreId,
    );
  }

  @override
  List<Object?> get props => [
        store,
        hasStore,
        isSaving,
        isLoadingStores,
        errorMessage,
        successMessage,
        accessibleStores,
        activeStoreId,
      ];
}

class StoreError extends StoreState {
  final String message;

  const StoreError(this.message);

  @override
  List<Object?> get props => [message];
}

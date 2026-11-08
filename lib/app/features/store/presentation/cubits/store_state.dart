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
    StoreEntity? restaurant,
    bool? hasStore,
    bool? hasRestaurant,
    this.isSaving = false,
    this.isLoadingStores = false,
    this.errorMessage,
    this.successMessage,
    this.accessibleStores = const [],
    this.activeStoreId,
  })  : store = store ??
            restaurant ??
            const StoreEntity(nameAr: '', nameEn: ''),
        hasStore = hasStore ?? hasRestaurant ?? false;

  /// Backward-compatibility getter
  StoreEntity get restaurant => store;
  bool get hasRestaurant => hasStore;
  StoreEntity get activeStore => store;

  StoreLoaded copyWith({
    StoreEntity? store,
    StoreEntity? restaurant,
    bool? hasStore,
    bool? hasRestaurant,
    bool? isSaving,
    bool? isLoadingStores,
    String? errorMessage,
    String? successMessage,
    List<StoreEntity>? accessibleStores,
    int? activeStoreId,
    bool clearMessages = false,
  }) {
    return StoreLoaded(
      store: store ?? restaurant ?? this.store,
      hasStore: hasStore ?? hasRestaurant ?? this.hasStore,
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

// Backward compatibility aliases
typedef RestaurantState = StoreState;
typedef RestaurantInitial = StoreInitial;
typedef RestaurantLoading = StoreLoading;
typedef RestaurantLoaded = StoreLoaded;
typedef RestaurantError = StoreError;

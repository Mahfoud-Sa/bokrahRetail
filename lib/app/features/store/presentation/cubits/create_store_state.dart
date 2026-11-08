import 'package:equatable/equatable.dart';
import '../../data/models/store_dto.dart';

class CreateStoreState extends Equatable {
  final bool isSubmitting;
  final bool isSuccess;
  final bool isNameError;
  final bool isUnauthorized;
  final bool isForbidden;
  final bool isDuplicateName;
  final bool isAlreadyHasStore;
  final String? errorMessage;
  final StoreResponseDto? createdStore;

  const CreateStoreState({
    required this.isSubmitting,
    required this.isSuccess,
    this.isNameError = false,
    this.isUnauthorized = false,
    this.isForbidden = false,
    this.isDuplicateName = false,
    this.isAlreadyHasStore = false,
    this.errorMessage,
    this.createdStore,
  });

  factory CreateStoreState.initial() => const CreateStoreState(
        isSubmitting: false,
        isSuccess: false,
      );

  // Backward compatibility getters
  bool get isAlreadyHasRestaurant => isAlreadyHasStore;
  StoreResponseDto? get createdRestaurant => createdStore;

  CreateStoreState copyWith({
    bool? isSubmitting,
    bool? isSuccess,
    bool? isNameError,
    bool? isUnauthorized,
    bool? isForbidden,
    bool? isDuplicateName,
    bool? isAlreadyHasStore,
    bool? isAlreadyHasRestaurant,
    String? errorMessage,
    StoreResponseDto? createdStore,
    StoreResponseDto? createdRestaurant,
    bool clearErrors = false,
  }) {
    return CreateStoreState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      isNameError: clearErrors ? false : (isNameError ?? this.isNameError),
      isUnauthorized:
          clearErrors ? false : (isUnauthorized ?? this.isUnauthorized),
      isForbidden: clearErrors ? false : (isForbidden ?? this.isForbidden),
      isDuplicateName:
          clearErrors ? false : (isDuplicateName ?? this.isDuplicateName),
      isAlreadyHasStore: clearErrors
          ? false
          : (isAlreadyHasStore ?? isAlreadyHasRestaurant ?? this.isAlreadyHasStore),
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      createdStore: createdStore ?? createdRestaurant ?? this.createdStore,
    );
  }

  @override
  List<Object?> get props => [
        isSubmitting,
        isSuccess,
        isNameError,
        isUnauthorized,
        isForbidden,
        isDuplicateName,
        isAlreadyHasStore,
        errorMessage,
        createdStore,
      ];
}

// Backward compatibility alias
typedef CreateRestaurantState = CreateStoreState;


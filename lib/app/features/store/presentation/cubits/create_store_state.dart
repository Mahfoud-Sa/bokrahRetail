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

  CreateStoreState copyWith({
    bool? isSubmitting,
    bool? isSuccess,
    bool? isNameError,
    bool? isUnauthorized,
    bool? isForbidden,
    bool? isDuplicateName,
    bool? isAlreadyHasStore,
    String? errorMessage,
    StoreResponseDto? createdStore,
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
          : (isAlreadyHasStore ?? this.isAlreadyHasStore),
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      createdStore: createdStore ?? this.createdStore,
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


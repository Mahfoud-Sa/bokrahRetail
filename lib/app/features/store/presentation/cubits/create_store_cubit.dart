import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/store_dto.dart';
import '../../data/services/store_api_service.dart';
import 'create_store_state.dart';
import 'store_cubit.dart';

class CreateStoreCubit extends Cubit<CreateStoreState> {
  final StoreApiService apiService;
  final StoreCubit? storeCubit;

  CreateStoreCubit({
    required this.apiService,
    this.storeCubit,
  }) : super(CreateStoreState.initial());

  Future<bool> submit(CreateStoreRequest request) async {
    if (!request.hasValidName) {
      emit(state.copyWith(
        isSubmitting: false,
        isNameError: true,
        errorMessage: 'Store name (or Arabic/English name) is required.',
      ));
      return false;
    }

    emit(state.copyWith(
      isSubmitting: true,
      clearErrors: true,
      isSuccess: false,
    ));

    try {
      final response = await apiService.createStore(request);

      if (storeCubit != null) {
        await storeCubit!.updateStore(response.toEntity(), markRegistered: true);
        storeCubit!.setHasStore(true);
      }

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        createdStore: response,
      ));
      return true;
    } on StoreValidationException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        isNameError: true,
        errorMessage: e.message,
      ));
      return false;
    } on StoreUnauthorizedException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        isUnauthorized: true,
        errorMessage: e.message,
      ));
      return false;
    } on StoreForbiddenException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        isForbidden: true,
        errorMessage: e.message,
      ));
      return false;
    } on StoreDuplicateNameException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        isDuplicateName: true,
        errorMessage: e.message,
      ));
      return false;
    } on StoreOwnerAlreadyHasStoreException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        isAlreadyHasStore: true,
        errorMessage: e.message,
      ));
      return false;
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/entities/user_entity.dart';
import '../../data/services/users_service.dart';
import 'session_state.dart';

class SessionCubit extends Cubit<SessionState> {
  final UsersService usersService;

  SessionCubit({required this.usersService, UserEntity? initialOperator})
      : super(SessionState(currentOperator: initialOperator)) {
    if (initialOperator == null) {
      loadInitialOperator();
    }
  }

  Future<void> loadInitialOperator() async {
    emit(state.copyWith(isLoading: true));
    final users = await usersService.getAllUsers();
    if (users.isNotEmpty) {
      emit(state.copyWith(
        currentOperator: users.first,
        isLoading: false,
      ));
    } else {
      emit(state.copyWith(isLoading: false));
    }
  }

  void switchOperator(UserEntity operator) {
    emit(state.copyWith(currentOperator: operator));
  }
}

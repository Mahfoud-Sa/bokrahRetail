import 'package:equatable/equatable.dart';
import '../../data/entities/user_entity.dart';

class SessionState extends Equatable {
  final UserEntity? currentOperator;
  final bool isLoading;

  const SessionState({
    this.currentOperator,
    this.isLoading = false,
  });

  OperatorRole get role => currentOperator?.role ?? OperatorRole.admin;
  bool get isAdmin => role == OperatorRole.admin;
  bool get isCashier => role == OperatorRole.cashier;
  bool get isAccountant => role == OperatorRole.accountant;

  bool get canAccessUsers => isAdmin;
  bool get canAccessAccounting => isAdmin || isAccountant;
  bool get canAccessSettings => isAdmin;

  SessionState copyWith({
    UserEntity? currentOperator,
    bool? isLoading,
  }) {
    return SessionState(
      currentOperator: currentOperator ?? this.currentOperator,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [currentOperator, isLoading];
}

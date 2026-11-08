import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';
import 'package:equatable/equatable.dart';

abstract class UnitState extends Equatable {
  const UnitState();

  @override
  List<Object?> get props => [];
}

class UnitInitial extends UnitState {}

class UnitLoading extends UnitState {}

class UnitLoaded extends UnitState {
  final List<UnitEntity> units;
  const UnitLoaded(this.units);

  @override
  List<Object?> get props => [units];
}

class UnitError extends UnitState {
  final String message;
  const UnitError(this.message);

  @override
  List<Object?> get props => [message];
}

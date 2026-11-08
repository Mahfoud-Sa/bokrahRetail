import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';
import 'package:bokrah_retail/app/features/units/domain/usecases/unit_usecases.dart';
import 'package:bokrah_retail/app/features/units/presentation/cubits/unit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UnitCubit extends Cubit<UnitState> {
  final GetAllUnitsUseCase getAllUnitsUseCase;
  final GetUnitsByItemIdUseCase getUnitsByItemIdUseCase;
  final SaveUnitsUseCase saveUnitsUseCase;
  final DeleteUnitsByItemIdUseCase deleteUnitsByItemIdUseCase;

  UnitCubit({
    required this.getAllUnitsUseCase,
    required this.getUnitsByItemIdUseCase,
    required this.saveUnitsUseCase,
    required this.deleteUnitsByItemIdUseCase,
  }) : super(UnitInitial());

  Future<void> loadAllUnits() async {
    emit(UnitLoading());
    try {
      final units = await getAllUnitsUseCase();
      emit(UnitLoaded(units));
    } catch (e) {
      emit(UnitError(e.toString()));
    }
  }

  Future<void> loadUnitsByItemId(int itemId) async {
    emit(UnitLoading());
    try {
      final units = await getUnitsByItemIdUseCase(itemId);
      emit(UnitLoaded(units));
    } catch (e) {
      emit(UnitError(e.toString()));
    }
  }

  Future<void> saveUnits(List<UnitEntity> units) async {
    try {
      final success = await saveUnitsUseCase(units);
      if (success) {
        await loadAllUnits();
      } else {
        emit(const UnitError('فشل حفظ الوحدات'));
      }
    } catch (e) {
      emit(UnitError(e.toString()));
    }
  }

  Future<void> deleteUnits(int itemId) async {
    try {
      final success = await deleteUnitsByItemIdUseCase(itemId);
      if (success) {
        await loadAllUnits();
      } else {
        emit(const UnitError('فشل حذف الوحدات'));
      }
    } catch (e) {
      emit(UnitError(e.toString()));
    }
  }
}

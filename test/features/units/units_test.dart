import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/units/data/datasources/unit_local_datasource.dart';
import 'package:bokrah_retail/app/features/units/data/repositories/unit_repository_impl.dart';
import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';
import 'package:bokrah_retail/app/features/units/domain/usecases/unit_usecases.dart';

void main() {
  group('Units Data & Domain', () {
    late SharedPreferences prefs;
    late UnitLocalDataSourceImpl dataSource;
    late UnitRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      dataSource = UnitLocalDataSourceImpl(sharedPreferences: prefs);
      repository = UnitRepositoryImpl(localDataSource: dataSource);
    });

    test('starts empty when storage has no units', () async {
      final units = await repository.getAllUnits();
      expect(units, isEmpty);
    });

    test('saves, updates, and deletes individual units', () async {
      final saved = await repository.saveUnit(
        const UnitEntity(
          name: 'حبة',
          factor: 1.0,
          itemId: 0,
          barcodes: ['1001'],
        ),
      );
      expect(saved, isNotNull);
      expect(saved!.id, isNotNull);
      expect(saved.name, 'حبة');

      final updatedOk = await repository.updateUnit(
        saved.copyWith(name: 'قطعة', factor: 2.0, barcodes: ['1001', '1002']),
      );
      expect(updatedOk, isTrue);

      final allAfterUpdate = await repository.getAllUnits();
      expect(allAfterUpdate.length, 1);
      expect(allAfterUpdate.first.name, 'قطعة');
      expect(allAfterUpdate.first.factor, 2.0);
      expect(allAfterUpdate.first.barcodes, ['1001', '1002']);

      final deletedOk = await repository.deleteUnit(saved.id!);
      expect(deletedOk, isTrue);
      expect(await repository.getAllUnits(), isEmpty);
    });

    test('SearchUnitsUseCase filters by name, factor, and barcode', () {
      final search = SearchUnitsUseCase();
      const list = [
        UnitEntity(id: 1, name: 'حبة', factor: 1.0, itemId: 0, barcodes: ['111']),
        UnitEntity(id: 2, name: 'كرتون', factor: 12.0, itemId: 0, barcodes: ['222']),
      ];

      expect(search(list, '').length, 2);
      expect(search(list, 'كرتون').map((u) => u.id), [2]);
      expect(search(list, '12').map((u) => u.id), [2]);
      expect(search(list, '111').map((u) => u.id), [1]);
      expect(search(list, 'missing'), isEmpty);
    });
  });
}

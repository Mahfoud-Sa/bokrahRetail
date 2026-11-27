import 'package:bokrah_retail/app/features/barcoders/data/repository/barcode_repository_imp.dart';
import 'package:bokrah_retail/app/features/barcoders/data/services/barcodes_service.dart';
import 'package:bokrah_retail/app/features/barcoders/domain/entities/barcode_entity.dart';
import 'package:bokrah_retail/app/features/barcoders/presentation/bloc/barcodes_cubit.dart';
import 'package:bokrah_retail/app/features/barcoders/presentation/bloc/barcodes_state.dart';
import 'package:bokrah_retail/app/features/barcoders/presentation/pages/barcoders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BarcodesCubit', () {
    test('loads, saves, updates, and deletes barcodes', () async {
      final cubit = BarcodesCubit(
        repository: BarcodeRepositoryImpl(service: BarcodesService()),
      );

      await cubit.loadBarcodes();
      expect(cubit.state.status, BarcodesStatus.loaded);
      expect(cubit.state.barcodes, isEmpty);

      final saved = await cubit.saveBarcode(
        BarcodeEntity(id: 1, code: '1234567890', label: 'Main'),
      );
      expect(saved, isTrue);
      expect(cubit.state.barcodes.length, 1);
      expect(cubit.state.barcodes.first.code, '1234567890');

      final updated = await cubit.updateBarcode(
        BarcodeEntity(id: 1, code: '999999', label: 'Updated'),
      );
      expect(updated, isTrue);
      expect(cubit.state.barcodes.first.code, '999999');

      final deleted = await cubit.deleteBarcode(1);
      expect(deleted, isTrue);
      expect(cubit.state.barcodes, isEmpty);

      await cubit.close();
    });

    test('syncs and unlinks M:M item-barcode relationships', () async {
      final service = BarcodesService();
      await service.saveBarcode(BarcodeEntity(id: 10, code: 'B-10'));
      await service.saveBarcode(BarcodeEntity(id: 20, code: 'B-20'));
      await service.saveBarcode(BarcodeEntity(id: 30, code: 'B-30'));

      // Link item 100 to barcodes 10 and 20
      await service.syncBarcodesForItem(100, {10, 20});
      expect(await service.getBarcodeIdsByItem(100), unorderedEquals([10, 20]));
      expect(await service.getItemIdsByBarcode(10), [100]);

      // Update links for item 100 to {20, 30}
      await service.syncBarcodesForItem(100, {20, 30});
      expect(await service.getBarcodeIdsByItem(100), unorderedEquals([20, 30]));
      expect(await service.getItemIdsByBarcode(10), isEmpty);
      expect(await service.getItemIdsByBarcode(30), [100]);

      // Unlink all when item is deleted
      await service.unlinkAllBarcodesForItem(100);
      expect(await service.getBarcodeIdsByItem(100), isEmpty);
      expect(await service.getItemIdsByBarcode(20), isEmpty);
      expect(await service.getItemIdsByBarcode(30), isEmpty);
    });
  });

  group('BarcodesPage', () {
    testWidgets('renders barcodes grid and filters by search query', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cubit = BarcodesCubit(
        repository: BarcodeRepositoryImpl(service: BarcodesService()),
      );
      await cubit.saveBarcode(BarcodeEntity(id: 1, code: '111222', label: 'A'));
      await cubit.saveBarcode(BarcodeEntity(id: 2, code: '333444', label: 'B'));

      await tester.pumpWidget(MaterialApp(home: BarcodesPage(cubit: cubit)));
      await tester.pumpAndSettle();

      expect(find.text('111222'), findsOneWidget);
      expect(find.text('333444'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '333444');
      await tester.pump();

      expect(
        find.descendant(of: find.byType(Card), matching: find.text('111222')),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byType(Card), matching: find.text('333444')),
        findsOneWidget,
      );

      await cubit.close();
    });
  });
}

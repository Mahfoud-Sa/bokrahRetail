import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/presentation/pages/items_page.dart';

void main() {
  late ItemsService itemsService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    itemsService = ItemsService();
  });

  testWidgets('ItemsPage renders empty state when there are no items', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ItemsPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('العناصر والمنتجات'), findsOneWidget);
    expect(find.text('إضافة عنصر'), findsOneWidget);
  });

  testWidgets(
    'ItemsPage renders multiple added items and filters by search query',
    (tester) async {
      await itemsService.saveItem(
        ItemEntity(
          name: 'شاشة سامسونج 27 بوصة',
          company: 'Samsung',
          brand: 'Odyssey',
          usageStatus: ItemUsageStatus.newItem,
          sellPrice: 1200,
          purchasePrice: 950,
          quantity: 6,
          barcodes: const ['8801001'],
        ),
      );
      await itemsService.saveItem(
        ItemEntity(
          name: 'لوحة مفاتيح ميكانيكية',
          company: 'Keychron',
          brand: 'K2',
          usageStatus: ItemUsageStatus.renew,
          sellPrice: 350,
          purchasePrice: 240,
          quantity: 14,
          barcodes: const ['8801002'],
        ),
      );
      await itemsService.saveItem(
        ItemEntity(
          name: 'سماعة رأس لاسلكية',
          company: 'Sony',
          brand: 'XM5',
          usageStatus: ItemUsageStatus.used,
          sellPrice: 800,
          purchasePrice: 600,
          quantity: 4,
          barcodes: const ['8801003'],
        ),
      );

      // Use a desktop-sized surface so all cards in the grid are laid out cleanly.
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: ItemsPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('شاشة سامسونج 27 بوصة'), findsOneWidget);
      expect(find.text('لوحة مفاتيح ميكانيكية'), findsOneWidget);
      expect(find.text('سماعة رأس لاسلكية'), findsOneWidget);

      // Search by barcode to narrow down to a single item
      await tester.enterText(find.byType(TextField), '8801002');
      await tester.pump();

      expect(find.text('لوحة مفاتيح ميكانيكية'), findsOneWidget);
      expect(find.text('شاشة سامسونج 27 بوصة'), findsNothing);
      expect(find.text('سماعة رأس لاسلكية'), findsNothing);
    },
  );
}

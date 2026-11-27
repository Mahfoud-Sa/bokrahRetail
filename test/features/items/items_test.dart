import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/barcoders/data/services/barcodes_service.dart';
import 'package:bokrah_retail/app/features/barcoders/domain/entities/barcode_entity.dart';
import 'package:bokrah_retail/app/features/items/data/datasources/items_local_datasource.dart';
import 'package:bokrah_retail/app/features/items/data/models/item_model.dart';
import 'package:bokrah_retail/app/features/items/data/repositories/items_repository_impl.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ItemEntity domain logic', () {
    test('calculates profit margin, percentage, and profitability', () {
      final profitable = ItemEntity(
        name: 'Coffee Beans',
        purchasePrice: 40.0,
        sellPrice: 60.0,
      );
      expect(profitable.profitMargin, 20.0);
      expect(profitable.profitPercentage, 50.0);
      expect(profitable.isProfitable, isTrue);

      final loss = ItemEntity(
        name: 'Clearance Item',
        purchasePrice: 50.0,
        sellPrice: 35.0,
      );
      expect(loss.profitMargin, -15.0);
      expect(loss.isProfitable, isFalse);

      final zeroPurchase = ItemEntity(
        name: 'Promo Gift',
        purchasePrice: 0.0,
        sellPrice: 10.0,
      );
      expect(zeroPurchase.profitPercentage, 0.0);
    });

    test('parses ItemUsageStatus from English, Arabic, and aliases', () {
      expect(ItemUsageStatus.fromString('new'), ItemUsageStatus.newItem);
      expect(ItemUsageStatus.fromString('جديد'), ItemUsageStatus.newItem);
      expect(ItemUsageStatus.fromString('renew'), ItemUsageStatus.renew);
      expect(ItemUsageStatus.fromString('مجدد'), ItemUsageStatus.renew);
      expect(ItemUsageStatus.fromString('open box'), ItemUsageStatus.renew);
      expect(ItemUsageStatus.fromString('used'), ItemUsageStatus.used);
      expect(ItemUsageStatus.fromString('مستعمل'), ItemUsageStatus.used);
      expect(ItemUsageStatus.fromString(null), ItemUsageStatus.newItem);
      expect(ItemUsageStatus.fromString('unknown'), ItemUsageStatus.newItem);
    });

    test('copyWith updates fields and supports clearing department/category', () {
      final original = ItemEntity(
        id: 10,
        name: 'Laptop',
        departmentId: 2,
        categoryId: 5,
        sellPrice: 3000.0,
        purchasePrice: 2400.0,
        quantity: 4,
      );

      final updated = original.copyWith(
        name: 'Gaming Laptop',
        sellPrice: 3500.0,
        clearDepartment: true,
        clearCategory: true,
      );

      expect(updated.id, 10);
      expect(updated.name, 'Gaming Laptop');
      expect(updated.sellPrice, 3500.0);
      expect(updated.purchasePrice, 2400.0);
      expect(updated.departmentId, isNull);
      expect(updated.categoryId, isNull);
    });
  });

  group('ItemModel serialization', () {
    test('round-trips all item fields through toMap and fromMap', () {
      final createdAt = DateTime(2026, 11, 27, 10, 30);
      final model = ItemModel(
        id: 42,
        name: 'Wireless Mouse',
        subname: 'Silent Click',
        usageStatus: ItemUsageStatus.renew,
        company: 'LogiTech',
        brand: 'MX',
        manufactureYear: 2025,
        shortDescription: 'Ergonomic mouse',
        fullDescription: 'Full wireless mouse description',
        barcodes: const ['628100000001', '628100000002'],
        advantages: const ['Rechargeable', 'Bluetooth'],
        sellPrice: 299.5,
        purchasePrice: 180.0,
        quantity: 15,
        qrCode: 'QR-MOUSE-42',
        departmentId: 3,
        categoryId: 7,
        createdAt: createdAt,
      );

      final restored = ItemModel.fromMap(model.toMap());
      expect(restored.id, 42);
      expect(restored.name, 'Wireless Mouse');
      expect(restored.effectiveSubname, 'Silent Click');
      expect(restored.usageStatus, ItemUsageStatus.renew);
      expect(restored.effectiveCompany, 'LogiTech');
      expect(restored.brand, 'MX');
      expect(restored.manufactureYear, 2025);
      expect(restored.shortDescription, 'Ergonomic mouse');
      expect(restored.effectiveFullDescription, 'Full wireless mouse description');
      expect(restored.barcodes, ['628100000001', '628100000002']);
      expect(restored.advantages, ['Rechargeable', 'Bluetooth']);
      expect(restored.sellPrice, 299.5);
      expect(restored.purchasePrice, 180.0);
      expect(restored.quantity, 15);
      expect(restored.qrCode, 'QR-MOUSE-42');
      expect(restored.departmentId, 3);
      expect(restored.categoryId, 7);
      expect(restored.createdAt, createdAt);
    });
  });

  group('Items Data, Repository & Service (multiple items)', () {
    late SharedPreferences prefs;
    late ItemsLocalDataSourceImpl localDataSource;
    late ItemsRepositoryImpl repository;
    late BarcodesService barcodesService;
    late ItemsService itemsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localDataSource = ItemsLocalDataSourceImpl(prefs: prefs);
      repository = ItemsRepositoryImpl(localDataSource: localDataSource);
      barcodesService = BarcodesService();
      itemsService = ItemsService(
        repository: repository,
        barcodesService: barcodesService,
      );
    });

    test('starts empty when storage has no items', () async {
      expect(await itemsService.getAllItems(), isEmpty);
    });

    test(
      'adds multiple items with unique IDs and preserves all fields including advantages',
      () async {
        final itemsToAdd = [
          ItemEntity(
            name: 'iPhone 16 Pro',
            subname: '256GB Titanium',
            usageStatus: ItemUsageStatus.newItem,
            company: 'Apple',
            brand: 'iPhone',
            sellPrice: 4500.0,
            purchasePrice: 3900.0,
            quantity: 10,
            barcodes: const ['10000001'],
            advantages: const ['5G', 'Ceramic Shield'],
            departmentId: 1,
            categoryId: 10,
          ),
          ItemEntity(
            name: 'Galaxy S25 Ultra',
            subname: '512GB Black',
            usageStatus: ItemUsageStatus.newItem,
            company: 'Samsung',
            brand: 'Galaxy',
            sellPrice: 4200.0,
            purchasePrice: 3600.0,
            quantity: 8,
            barcodes: const ['10000002'],
            advantages: const ['S-Pen', '200MP Camera'],
            departmentId: 1,
            categoryId: 10,
          ),
          ItemEntity(
            name: 'MacBook Air M3',
            usageStatus: ItemUsageStatus.renew,
            company: 'Apple',
            brand: 'MacBook',
            sellPrice: 3800.0,
            purchasePrice: 3200.0,
            quantity: 5,
            barcodes: const ['10000003'],
            advantages: const ['Lightweight'],
            departmentId: 2,
            categoryId: 20,
          ),
          ItemEntity(
            name: 'Sony WH-1000XM5',
            usageStatus: ItemUsageStatus.used,
            company: 'Sony',
            brand: 'WH',
            sellPrice: 950.0,
            purchasePrice: 700.0,
            quantity: 12,
            barcodes: const ['10000004'],
            advantages: const ['ANC'],
            departmentId: 3,
            categoryId: 30,
          ),
          ItemEntity(
            name: 'Anker PowerCore 20K',
            usageStatus: ItemUsageStatus.newItem,
            company: 'Anker',
            sellPrice: 180.0,
            purchasePrice: 110.0,
            quantity: 30,
            barcodes: const ['10000005'],
            advantages: const ['Fast Charge', 'USB-C'],
            departmentId: 3,
            categoryId: 31,
          ),
        ];

        final savedItems = <ItemEntity>[];
        for (final item in itemsToAdd) {
          final saved = await itemsService.saveItem(item);
          expect(saved, isNotNull);
          expect(saved!.id, isNotNull);
          savedItems.add(saved);
        }

        // Every saved item must have a distinct ID even when saved back-to-back
        final uniqueIds = savedItems.map((e) => e.id).toSet();
        expect(uniqueIds.length, itemsToAdd.length);

        final allStored = await itemsService.getAllItems();
        expect(allStored.length, 5);
        expect(
          allStored.map((e) => e.name).toList(),
          [
            'iPhone 16 Pro',
            'Galaxy S25 Ultra',
            'MacBook Air M3',
            'Sony WH-1000XM5',
            'Anker PowerCore 20K',
          ],
        );

        // Verify advantages and lookups by ID
        final first = await itemsService.getItemById(savedItems.first.id!);
        expect(first, isNotNull);
        expect(first!.advantages, ['5G', 'Ceramic Shield']);

        final last = await itemsService.getItemById(savedItems.last.id!);
        expect(last, isNotNull);
        expect(last!.advantages, ['Fast Charge', 'USB-C']);
      },
    );

    test(
      'updates one item among multiple items without affecting others',
      () async {
        final itemA = await itemsService.saveItem(
          ItemEntity(name: 'Item A', sellPrice: 100, purchasePrice: 60, quantity: 5),
        );
        final itemB = await itemsService.saveItem(
          ItemEntity(name: 'Item B', sellPrice: 200, purchasePrice: 120, quantity: 10),
        );
        final itemC = await itemsService.saveItem(
          ItemEntity(name: 'Item C', sellPrice: 300, purchasePrice: 200, quantity: 15),
        );

        final updatedOk = await itemsService.updateItem(
          itemB!.copyWith(name: 'Item B Updated', sellPrice: 250, quantity: 20),
        );
        expect(updatedOk, isTrue);

        final all = await itemsService.getAllItems();
        expect(all.length, 3);
        expect(all.firstWhere((e) => e.id == itemA!.id).name, 'Item A');
        final updatedB = all.firstWhere((e) => e.id == itemB.id);
        expect(updatedB.name, 'Item B Updated');
        expect(updatedB.sellPrice, 250);
        expect(updatedB.quantity, 20);
        expect(all.firstWhere((e) => e.id == itemC!.id).name, 'Item C');
      },
    );

    test(
      'deletes one item among multiple items and unlinks its barcodes',
      () async {
        final item1 = await itemsService.saveItem(
          ItemEntity(name: 'Keep Item 1', sellPrice: 50, quantity: 2),
        );
        final item2 = await itemsService.saveItem(
          ItemEntity(name: 'Delete Me', sellPrice: 75, quantity: 3),
        );
        final item3 = await itemsService.saveItem(
          ItemEntity(name: 'Keep Item 3', sellPrice: 90, quantity: 4),
        );

        final savedBarcode = await barcodesService.saveBarcode(
          BarcodeEntity(id: 101, code: 'BC-DEL-001'),
        );
        expect(savedBarcode, isTrue);
        await barcodesService.linkItemToBarcode(item2!.id!, 101);
        expect(await barcodesService.getBarcodeIdsByItem(item2.id!), [101]);

        final deletedOk = await itemsService.deleteItem(item2.id!);
        expect(deletedOk, isTrue);

        final remaining = await itemsService.getAllItems();
        expect(remaining.length, 2);
        expect(remaining.map((e) => e.id).toSet(), {item1!.id, item3!.id});
        expect(await barcodesService.getBarcodeIdsByItem(item2.id!), isEmpty);
      },
    );

    test('skips corrupted JSON entries gracefully when reading items', () async {
      await prefs.setStringList('items_list', [
        'not valid json',
        '{"id": 1, "name": "Valid Item", "sellPrice": 25.0, "purchasePrice": 15.0, "quantity": 4}',
      ]);

      final items = await itemsService.getAllItems();
      expect(items.length, 1);
      expect(items.first.name, 'Valid Item');
    });
  });
}

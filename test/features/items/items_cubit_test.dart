import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/items/data/datasources/items_local_datasource.dart';
import 'package:bokrah_retail/app/features/items/data/repositories/items_repository_impl.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/usecases/item_usecases.dart';
import 'package:bokrah_retail/app/features/items/presentation/cubits/items_cubit.dart';
import 'package:bokrah_retail/app/features/items/presentation/cubits/items_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ItemsCubit', () {
    late ItemsCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ItemsRepositoryImpl(
        localDataSource: ItemsLocalDataSourceImpl(prefs: prefs),
      );

      cubit = ItemsCubit(
        getAllItemsUseCase: GetAllItemsUseCase(repository),
        getItemByIdUseCase: GetItemByIdUseCase(repository),
        saveItemUseCase: SaveItemUseCase(repository),
        updateItemUseCase: UpdateItemUseCase(repository),
        deleteItemUseCase: DeleteItemUseCase(repository),
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('starts in ItemsInitial and loads empty list', () async {
      expect(cubit.state, isA<ItemsInitial>());

      await cubit.loadAllItems();
      expect(cubit.state, isA<ItemsLoaded>());
      expect((cubit.state as ItemsLoaded).items, isEmpty);
    });

    test('adds multiple items sequentially and reloads ItemsLoaded state', () async {
      final first = await cubit.saveItem(
        ItemEntity(name: 'Milk 1L', sellPrice: 7.5, purchasePrice: 5.0, quantity: 40),
      );
      final second = await cubit.saveItem(
        ItemEntity(name: 'Olive Oil 500ml', sellPrice: 32.0, purchasePrice: 22.0, quantity: 15),
      );
      final third = await cubit.saveItem(
        ItemEntity(name: 'Basmati Rice 5kg', sellPrice: 45.0, purchasePrice: 35.0, quantity: 20),
      );

      expect(first?.id, isNotNull);
      expect(second?.id, isNotNull);
      expect(third?.id, isNotNull);
      expect({first!.id, second!.id, third!.id}.length, 3);

      expect(cubit.state, isA<ItemsLoaded>());
      final loadedItems = (cubit.state as ItemsLoaded).items;
      expect(loadedItems.length, 3);
      expect(
        loadedItems.map((e) => e.name).toList(),
        ['Milk 1L', 'Olive Oil 500ml', 'Basmati Rice 5kg'],
      );
    });

    test('updates and deletes items among multiple saved items', () async {
      final item1 = await cubit.saveItem(
        ItemEntity(name: 'Shampoo', sellPrice: 25, purchasePrice: 15, quantity: 12),
      );
      final item2 = await cubit.saveItem(
        ItemEntity(name: 'Soap Bar', sellPrice: 6, purchasePrice: 3, quantity: 50),
      );
      final item3 = await cubit.saveItem(
        ItemEntity(name: 'Toothpaste', sellPrice: 12, purchasePrice: 7, quantity: 30),
      );

      final updated = await cubit.updateItem(
        item2!.copyWith(name: 'Herbal Soap Bar', sellPrice: 8),
      );
      expect(updated, isTrue);

      var loaded = (cubit.state as ItemsLoaded).items;
      expect(loaded.length, 3);
      expect(loaded.firstWhere((e) => e.id == item2.id).name, 'Herbal Soap Bar');

      final deleted = await cubit.deleteItem(item1!.id!);
      expect(deleted, isTrue);

      loaded = (cubit.state as ItemsLoaded).items;
      expect(loaded.length, 2);
      expect(loaded.map((e) => e.id).toSet(), {item2.id, item3!.id});
    });
  });
}

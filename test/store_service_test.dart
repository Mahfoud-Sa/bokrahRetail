import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/store/data/models/store_entity.dart';
import 'package:bokrah_retail/app/features/store/data/services/store_service.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_cubit.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StoreEntity Tests', () {
    test('serializes and deserializes to/from map correctly', () {
      final sample = StoreEntity(
        nameAr: 'مطعم الشام الأصيل',
        nameEn: 'Al Sham Authentic Restaurant',
        taxNumber: '310987654321003',
        commercialRegistration: '1010998877',
        taxRate: 15.0,
        currency: 'SAR',
        city: 'جدة',
        district: 'حي الروضة',
        receiptHeaderNote: 'مرحباً بكم في فرعنا الجديد',
      );

      final map = sample.toMap();
      final restored = StoreEntity.fromMap(map);

      expect(restored.nameAr, equals('مطعم الشام الأصيل'));
      expect(restored.nameEn, equals('Al Sham Authentic Restaurant'));
      expect(restored.taxNumber, equals('310987654321003'));
      expect(restored.commercialRegistration, equals('1010998877'));
      expect(restored.city, equals('جدة'));
      expect(restored.district, equals('حي الروضة'));
      expect(restored.receiptHeaderNote, equals('مرحباً بكم في فرعنا الجديد'));
    });
  });

  group('StoreService Tests', () {
    test('seeds default store when storage is empty', () async {
      final service = StoreService();
      final info = await service.getStoreInfo();

      expect(info, isNotNull);
      expect(info.nameAr, equals('متجر بكرة'));
      expect(info.taxRate, equals(15.0));
      expect(info.currency, equals('SAR'));
      expect(info.taxNumber, isNotEmpty);
      expect(info.commercialRegistration, isNotEmpty);
    });

    test('updates and persists store data correctly', () async {
      final service = StoreService();
      final initial = await service.getStoreInfo();

      final updated = initial.copyWith(
        nameAr: 'مطعم بكرة الذهبي',
        city: 'الدمام',
        taxNumber: '399999999900003',
        taxRate: 5.0,
      );

      final saveResult = await service.updateStoreInfo(updated);
      expect(saveResult, isTrue);

      final reloaded = await service.getStoreInfo();
      expect(reloaded.nameAr, equals('مطعم بكرة الذهبي'));
      expect(reloaded.city, equals('الدمام'));
      expect(reloaded.taxNumber, equals('399999999900003'));
      expect(reloaded.taxRate, equals(5.0));
    });

    test('resets to defaults cleanly', () async {
      final service = StoreService();
      final initial = await service.getStoreInfo();

      await service.updateStoreInfo(initial.copyWith(nameAr: 'مطعم مؤقت'));
      final modified = await service.getStoreInfo();
      expect(modified.nameAr, equals('مطعم مؤقت'));

      final reset = await service.resetToDefaults();
      expect(reset.nameAr, equals('متجر بكرة'));

      final fetched = await service.getStoreInfo();
      expect(fetched.nameAr, equals('متجر بكرة'));
    });
  });

  group('StoreCubit Tests', () {
    test('loads store and updates state', () async {
      final service = StoreService();
      final cubit = StoreCubit(service: service);

      expect(cubit.state, isA<StoreInitial>());

      await cubit.loadStore();
      expect(cubit.state, isA<StoreLoaded>());

      final loadedState = cubit.state as StoreLoaded;
      expect(loadedState.store.nameAr, equals('متجر بكرة'));

      final updated = loadedState.store.copyWith(nameAr: 'مطعم السفير');
      final success = await cubit.updateStore(updated);
      expect(success, isTrue);

      final newLoaded = cubit.state as StoreLoaded;
      expect(newLoaded.store.nameAr, equals('مطعم السفير'));
      expect(newLoaded.successMessage, isNotNull);
    });
  });
}

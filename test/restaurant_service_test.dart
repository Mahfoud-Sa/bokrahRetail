import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/restaurant/data/models/restaurant_entity.dart';
import 'package:bokrah_retail/app/features/restaurant/data/services/restaurant_service.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/cubits/restaurant_cubit.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/cubits/restaurant_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RestaurantEntity Tests', () {
    test('serializes and deserializes to/from map correctly', () {
      final sample = RestaurantEntity(
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
      final restored = RestaurantEntity.fromMap(map);

      expect(restored.nameAr, equals('مطعم الشام الأصيل'));
      expect(restored.nameEn, equals('Al Sham Authentic Restaurant'));
      expect(restored.taxNumber, equals('310987654321003'));
      expect(restored.commercialRegistration, equals('1010998877'));
      expect(restored.city, equals('جدة'));
      expect(restored.district, equals('حي الروضة'));
      expect(restored.receiptHeaderNote, equals('مرحباً بكم في فرعنا الجديد'));
    });
  });

  group('RestaurantService Tests', () {
    test('seeds default restaurant when storage is empty', () async {
      final service = RestaurantService();
      final info = await service.getRestaurantInfo();

      expect(info, isNotNull);
      expect(info.nameAr, equals('مطعم بكرة'));
      expect(info.taxRate, equals(15.0));
      expect(info.currency, equals('SAR'));
      expect(info.taxNumber, isNotEmpty);
      expect(info.commercialRegistration, isNotEmpty);
    });

    test('updates and persists restaurant data correctly', () async {
      final service = RestaurantService();
      final initial = await service.getRestaurantInfo();

      final updated = initial.copyWith(
        nameAr: 'مطعم بكرة الذهبي',
        city: 'الدمام',
        taxNumber: '399999999900003',
        taxRate: 5.0,
      );

      final saveResult = await service.updateRestaurantInfo(updated);
      expect(saveResult, isTrue);

      final reloaded = await service.getRestaurantInfo();
      expect(reloaded.nameAr, equals('مطعم بكرة الذهبي'));
      expect(reloaded.city, equals('الدمام'));
      expect(reloaded.taxNumber, equals('399999999900003'));
      expect(reloaded.taxRate, equals(5.0));
    });

    test('resets to defaults cleanly', () async {
      final service = RestaurantService();
      final initial = await service.getRestaurantInfo();

      await service.updateRestaurantInfo(initial.copyWith(nameAr: 'مطعم مؤقت'));
      final modified = await service.getRestaurantInfo();
      expect(modified.nameAr, equals('مطعم مؤقت'));

      final reset = await service.resetToDefaults();
      expect(reset.nameAr, equals('مطعم بكرة'));

      final fetched = await service.getRestaurantInfo();
      expect(fetched.nameAr, equals('مطعم بكرة'));
    });
  });

  group('RestaurantCubit Tests', () {
    test('loads restaurant and updates state', () async {
      final service = RestaurantService();
      final cubit = RestaurantCubit(service: service);

      expect(cubit.state, isA<RestaurantInitial>());

      await cubit.loadRestaurant();
      expect(cubit.state, isA<RestaurantLoaded>());

      final loadedState = cubit.state as RestaurantLoaded;
      expect(loadedState.restaurant.nameAr, equals('مطعم بكرة'));

      final updated = loadedState.restaurant.copyWith(nameAr: 'مطعم السفير');
      final success = await cubit.updateRestaurant(updated);
      expect(success, isTrue);

      final newLoaded = cubit.state as RestaurantLoaded;
      expect(newLoaded.restaurant.nameAr, equals('مطعم السفير'));
      expect(newLoaded.successMessage, isNotNull);
    });
  });
}

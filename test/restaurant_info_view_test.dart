import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/restaurant/data/models/restaurant_entity.dart';
import 'package:bokrah_retail/app/features/restaurant/data/services/restaurant_service.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/cubits/restaurant_cubit.dart';
import 'package:bokrah_retail/app/features/restaurant/presentation/pages/restaurant_info_page.dart';
import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:bokrah_retail/app/features/users/data/services/users_service.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late RestaurantService restaurantService;
  late RestaurantCubit restaurantCubit;
  late UsersService usersService;
  late SessionCubit sessionCubit;
  late SettingsCubit settingsCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    restaurantService = RestaurantService();
    restaurantCubit = RestaurantCubit(service: restaurantService);
    usersService = UsersService();
    sessionCubit = SessionCubit(usersService: usersService);
    settingsCubit = SettingsCubit(
      localDataSource: SettingsLocalDataSource(sharedPreferences: prefs),
    );

    // Seed admin operator for full access
    final adminUser = UserEntity(
      id: 1,
      name: 'مدير النظام',
      email: 'admin@bokrah.com',
      role: OperatorRole.admin,
    );
    sessionCubit.switchOperator(adminUser);

    // Seed comprehensive restaurant data
    const customRestaurant = RestaurantEntity(
      id: 'rest_101',
      nameAr: 'مطعم روابي الشام',
      nameEn: 'Rawabi Al-Sham Restaurant',
      slogan: 'الأصالة والمذاق الرفيع',
      subtitle: 'مشويات ومأكولات شرقية فاخرة',
      description: 'مطعم متميز يقدم تشكيلة واسعة من المشويات الحلبية والشرقية.',
      website: 'https://rawabi-alsham.com',
      phoneNumber: '0119876543',
      mobileNumber: '+966555112233',
      phoneNumbers: [
        RestaurantPhoneNumberInput(number: '+966555112233', type: 'Mobile'),
        RestaurantPhoneNumberInput(number: '0119876543', type: 'Landline'),
        RestaurantPhoneNumberInput(number: '+966509988776', type: 'WhatsApp'),
      ],
      country: 'المملكة العربية السعودية',
      city: 'الرياض',
      district: 'حي العليا',
      street: 'شارع التحلية',
      googleMapsUrl: 'https://maps.google.com/?q=24.7136,46.6753',
      latitude: 24.7136,
      longitude: 46.6753,
      ownerName: 'محمود الصالح',
    );
    await restaurantService.updateRestaurantInfo(customRestaurant);
    await restaurantCubit.loadRestaurant();
  });

  Widget buildHarness({Locale locale = const Locale('ar')}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RestaurantCubit>.value(value: restaurantCubit),
        BlocProvider<SessionCubit>.value(value: sessionCubit),
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RestaurantInfoPage(),
      ),
    );
  }

  group('RestaurantInfoPage Data View Tests', () {
    testWidgets('displays subtitle, description, owner, maps, and phones in restaurant view', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Verify Hero Banner displays restaurant data
      expect(find.text('مطعم روابي الشام'), findsWidgets);
      expect(find.text('مشويات ومأكولات شرقية فاخرة'), findsWidgets);
      expect(find.textContaining('المالك: محمود الصالح'), findsOneWidget);
      expect(find.text('موقع الخريطة متاح'), findsOneWidget);
      // Verify no 'Add Restaurant' button is shown since system only has one restaurant
      expect(find.byKey(const ValueKey('hero_add_restaurant_button')), findsNothing);

      // Verify Identity Tab fields
      expect(find.text('مطعم متميز يقدم تشكيلة واسعة من المشويات الحلبية والشرقية.'), findsWidgets);
      expect(find.text('محمود الصالح'), findsWidgets);

      // Switch to Contact & Address Tab (Tab index 2)
      final contactTab = find.byIcon(Icons.contact_mail_outlined);
      expect(contactTab, findsOneWidget);
      await tester.tap(contactTab);
      await tester.pumpAndSettle();

      // Check contact and location data in Tab 3
      expect(find.text('https://rawabi-alsham.com'), findsOneWidget);
      expect(find.text('https://maps.google.com/?q=24.7136,46.6753'), findsOneWidget);
      expect(find.text('24.7136'), findsOneWidget);
      expect(find.text('46.6753'), findsOneWidget);

      // Check dynamic phone numbers
      expect(find.text('+966555112233'), findsWidgets);
      expect(find.text('+966509988776'), findsOneWidget);
    });
  });
}

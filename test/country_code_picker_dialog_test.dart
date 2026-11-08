import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/auth/data/models/country_code_model.dart';
import 'package:bokrah_retail/app/features/auth/presentation/widgets/country_code_picker_dialog.dart';

Widget createTestDialogApp({
  required CountryCodeModel selectedCountry,
  required ValueChanged<CountryCodeModel> onSelect,
  Locale locale = const Locale('ar'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CountryCodePickerDialog(
        selectedCountry: selectedCountry,
        onSelect: onSelect,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CountryCodePickerDialog with Yemen Tests', () {
    test('CountryCodeModel.supportedCountries contains Yemen', () {
      final yemen = CountryCodeModel.supportedCountries.firstWhere(
        (c) => c.isoCode == 'YE',
      );
      expect(yemen.nameEn, equals('Yemen'));
      expect(yemen.nameAr, equals('اليمن'));
      expect(yemen.dialCode, equals('+967'));
      expect(yemen.flagEmoji, equals('🇾🇪'));
      expect(yemen.isValid('771234567'), isTrue);
      expect(yemen.normalize('771234567'), equals('+967771234567'));
    });

    testWidgets('displays Yemen in Arabic in the country bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      CountryCodeModel? selected;
      await tester.pumpWidget(createTestDialogApp(
        selectedCountry: CountryCodeModel.defaultCountry,
        onSelect: (c) => selected = c,
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      // Find Yemen in list
      expect(find.text('اليمن'), findsOneWidget);
      expect(find.text('+967'), findsOneWidget);
      expect(find.text('🇾🇪'), findsOneWidget);

      // Tap on Yemen
      await tester.tap(find.text('اليمن'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.isoCode, equals('YE'));
      expect(selected!.dialCode, equals('+967'));
    });

    testWidgets('filters country list when searching for Yemen in English and Arabic', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      CountryCodeModel? selected;
      await tester.pumpWidget(createTestDialogApp(
        selectedCountry: CountryCodeModel.defaultCountry,
        onSelect: (c) => selected = c,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      // Search by English name
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Yemen');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Yemen'), findsOneWidget);
      expect(find.text('+967'), findsOneWidget);

      // Search by dial code
      await tester.enterText(searchField, '+967');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Yemen'), findsOneWidget);
      expect(find.widgetWithText(ListTile, '+967'), findsOneWidget);

      await tester.tap(find.widgetWithText(ListTile, 'Yemen'));
      await tester.pumpAndSettle();
      expect(selected?.dialCode, equals('+967'));
    });
  });
}

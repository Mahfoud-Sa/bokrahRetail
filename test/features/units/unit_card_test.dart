import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';
import 'package:bokrah_retail/app/features/units/presentation/widgets/unit_card.dart';

void main() {
  testWidgets('UnitCard renders unit details and invokes edit/delete callbacks', (
    tester,
  ) async {
    var editTapped = false;
    var deleteTapped = false;

    const unit = UnitEntity(
      id: 1,
      name: 'Piece',
      factor: 1.0,
      itemId: 0,
      barcodes: ['12345'],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: UnitCard(
            unit: unit,
            onEdit: () => editTapped = true,
            onDelete: () => deleteTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Piece'), findsOneWidget);
    expect(find.text('Base Unit'), findsOneWidget);
    expect(find.text('Factor: 1.0'), findsOneWidget);
    expect(find.text('1 barcodes'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.tap(find.byIcon(Icons.delete_outline));

    expect(editTapped, isTrue);
    expect(deleteTapped, isTrue);
  });
}

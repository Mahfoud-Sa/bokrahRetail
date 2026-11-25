import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/companies/presentation/widgets/company_card.dart';

void main() {
  group('CompanyCard Widget Tests', () {
    final testCompany = CompanyEntity(
      id: 1,
      name: 'Apple',
      arabicName: 'أبل',
      englishName: 'Apple Inc.',
      code: 'AAPL',
      brands: const ['iPhone', 'iPad', 'Mac'],
    );

    testWidgets('renders company details, brands, and items count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 350,
              child: CompanyCard(
                company: testCompany,
                linkedItemsCount: 12,
              ),
            ),
          ),
        ),
      );

      expect(find.text('أبل'), findsOneWidget);
      expect(find.text('Apple Inc.'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text('12 عنصر مسجل'), findsOneWidget);
      expect(find.text('iPhone'), findsOneWidget);
      expect(find.text('iPad'), findsOneWidget);
      expect(find.text('Mac'), findsOneWidget);
    });

    testWidgets('triggers action callbacks when interacting with details and buttons', (tester) async {
      bool detailsClicked = false;
      bool editClicked = false;
      bool deleteClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 350,
              child: CompanyCard(
                company: testCompany,
                actions: CompanyCardActions(
                  onDetails: () => detailsClicked = true,
                  onEdit: () => editClicked = true,
                  onDelete: () => deleteClicked = true,
                ),
              ),
            ),
          ),
        ),
      );

      // Tap on Details text button in footer
      await tester.tap(find.text('التفاصيل'));
      await tester.pumpAndSettle();
      expect(detailsClicked, isTrue);

      // Tap on Edit button in footer
      await tester.tap(find.byTooltip('تعديل'));
      await tester.pumpAndSettle();
      expect(editClicked, isTrue);

      // Tap on Delete button in footer
      await tester.tap(find.byTooltip('حذف'));
      await tester.pumpAndSettle();
      expect(deleteClicked, isTrue);
    });
  });
}

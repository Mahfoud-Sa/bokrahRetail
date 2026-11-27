import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';

void main() {
  group('FormActionBar Widget Tests', () {
    testWidgets('renders submit and cancel buttons with callbacks', (
      tester,
    ) async {
      bool submitted = false;
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormActionBar(
              cancelLabel: 'إلغاء',
              submitLabel: 'حفظ الفئة',
              onSubmit: () => submitted = true,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );

      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('حفظ الفئة'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('حفظ الفئة'));
      expect(submitted, isTrue);

      await tester.tap(find.text('إلغاء'));
      expect(cancelled, isTrue);
    });

    testWidgets(
      'renders loading spinner and disables buttons when isSubmitting',
      (tester) async {
        bool submitted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FormActionBar(
                isSubmitting: true,
                submitLabel: 'حفظ الفئة',
                submittingLabel: 'جارٍ الحفظ...',
                onSubmit: () => submitted = true,
                onCancel: () {},
              ),
            ),
          ),
        );

        expect(find.text('جارٍ الحفظ...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.tap(find.text('جارٍ الحفظ...'));
        expect(submitted, isFalse);
      },
    );
  });
}

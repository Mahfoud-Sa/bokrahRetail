import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';

void main() {
  group('ResponsiveFormGrid Widget Tests', () {
    testWidgets('renders single-column layout on compact viewport < 900', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResponsiveFormGrid(
                header: const Text('Header Widget'),
                sections: const [
                  Card(child: Text('Section 1')),
                  Card(child: Text('Section 2')),
                  Card(child: Text('Section 3')),
                ],
                footer: const Text('Footer Widget'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Header Widget'), findsOneWidget);
      expect(find.text('Section 1'), findsOneWidget);
      expect(find.text('Section 2'), findsOneWidget);
      expect(find.text('Section 3'), findsOneWidget);
      expect(find.text('Footer Widget'), findsOneWidget);

      // On narrow viewport, no 2-item Row is created for sections
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('renders 2-column grid layout on desktop viewport >= 900', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResponsiveFormGrid(
                header: const Text('Header Widget'),
                sections: const [
                  Card(child: Text('Section 1')),
                  Card(child: Text('Section 2')),
                  Card(child: Text('Section 3')),
                  Card(child: Text('Section 4')),
                ],
                footer: const Text('Footer Widget'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Header Widget'), findsOneWidget);
      expect(find.text('Section 1'), findsOneWidget);
      expect(find.text('Section 2'), findsOneWidget);
      expect(find.text('Section 3'), findsOneWidget);
      expect(find.text('Section 4'), findsOneWidget);
      expect(find.text('Footer Widget'), findsOneWidget);

      // On wide viewport, 2 rows of 2 columns are created
      expect(find.byType(Row), findsNWidgets(2));
    });
  });
}

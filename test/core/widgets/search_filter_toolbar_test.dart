import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';

void main() {
  group('SearchFilterToolbar Widget Tests', () {
    testWidgets('renders search field, invokes callbacks, and shows actions', (
      tester,
    ) async {
      final controller = TextEditingController();
      String query = '';
      bool cleared = false;
      bool actionClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterToolbar(
              controller: controller,
              hintText: 'البحث في الفئات...',
              onSearchChanged: (v) => query = v,
              onClear: () {
                cleared = true;
                controller.clear();
              },
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => actionClicked = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('البحث في الفئات...'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'electronics');
      expect(query, 'electronics');

      await tester.pump();
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      expect(cleared, isTrue);

      await tester.tap(find.byIcon(Icons.add));
      expect(actionClicked, isTrue);
    });
  });
}

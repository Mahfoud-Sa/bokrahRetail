import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/items/data/models/item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ItemAdvantagesSection', () {
    testWidgets('adds multiple advantages and removes one', (tester) async {
      List<String> current = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ItemAdvantagesSection(
                  advantages: current,
                  onAdvantagesChanged: (updated) {
                    setState(() => current = updated);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('لا توجد مميزات مضافة بعد'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ضمان سنتين');
      await tester.tap(find.text('إضافة'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'مقاوم للماء');
      await tester.tap(find.text('إضافة'));
      await tester.pump();

      expect(current, ['ضمان سنتين', 'مقاوم للماء']);
      expect(find.text('ضمان سنتين'), findsOneWidget);
      expect(find.text('مقاوم للماء'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(current, ['مقاوم للماء']);
    });
  });

  group('ItemModel advantages serialization', () {
    test('roundtrips advantages through toMap and fromMap', () {
      final model = ItemModel(
        name: 'Test Item',
        advantages: const ['خفيف الوزن', 'بطارية طويلة'],
      );

      final map = model.toMap();
      final restored = ItemModel.fromMap(map);

      expect(restored.advantages, ['خفيف الوزن', 'بطارية طويلة']);
    });
  });
}

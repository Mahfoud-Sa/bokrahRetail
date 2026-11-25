import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/widgets/cards/stat_metric_card.dart';

void main() {
  group('StatMetricCard Widget Tests', () {
    testWidgets('renders title, value, icon, and default styling accurately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatMetricCard(
              title: 'إجمالي الشركات',
              value: '42',
              icon: Icons.corporate_fare,
            ),
          ),
        ),
      );

      expect(find.text('إجمالي الشركات'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(Icons.corporate_fare), findsOneWidget);
    });

    testWidgets('renders custom style with subtitle and color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatMetricCard(
              title: 'العلامات التجارية',
              value: '150',
              icon: Icons.branding_watermark,
              style: StatMetricStyle(
                subtitle: 'علامة نشطة',
                color: AppTheme.warmOrange,
              ),
            ),
          ),
        ),
      );

      expect(find.text('العلامات التجارية'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('علامة نشطة'), findsOneWidget);
      expect(find.byIcon(Icons.branding_watermark), findsOneWidget);
    });
  });
}

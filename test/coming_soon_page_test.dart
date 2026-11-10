import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/features/common/presentation/pages/coming_soon_page.dart';

void main() {
  Widget buildTestableWidget(
    Widget child, {
    Locale locale = const Locale('ar'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: child,
    );
  }

  group('ComingSoonView Tests', () {
    testWidgets('renders default Arabic text and badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('قريباً'), findsOneWidget);
      expect(find.text('قيد التطوير'), findsOneWidget);
      expect(find.text('العودة للرئيسية'), findsOneWidget);
      expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
    });

    testWidgets('renders default English text and badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coming Soon'), findsOneWidget);
      expect(find.text('In Development'), findsOneWidget);
      expect(find.text('Back to Dashboard'), findsOneWidget);
    });

    testWidgets('renders barcodes feature view in Arabic and English',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.barcodes()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إدارة الباركود والماسح الضوئي'), findsOneWidget);
      expect(find.text('تحديث v3.5.0'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      expect(find.text('توليد وطباعة ملصقات الباركود بمقاسات مختلفة (حراري / A4)'),
          findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.barcodes()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Barcode & Scanner Management'), findsOneWidget);
    });

    testWidgets('renders invoices feature view in Arabic and English',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.invoices()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إدارة الفواتير ونقاط البيع'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.invoices()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invoices & POS Management'), findsOneWidget);
    });

    testWidgets('renders items feature view in Arabic and English',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.items()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('كتالوج الأصناف والمنتجات'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_rounded), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.items()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Items & Products Catalog'), findsOneWidget);
    });

    testWidgets('renders units feature view in Arabic and English',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.units()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('وحدات القياس والتحويلات'), findsOneWidget);
      expect(find.byIcon(Icons.straighten_rounded), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.units()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Units & Packaging Conversions'), findsOneWidget);
    });

    testWidgets('renders warehouses feature view in Arabic and English',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.warehouses()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إدارة المستودعات وحركات المخزون'), findsOneWidget);
      expect(find.byIcon(Icons.warehouse_rounded), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.warehouses()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Warehouses & Inventory Movement'), findsOneWidget);
    });

    testWidgets('renders categories feature view in Arabic and English',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.categories()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('فئات المنتجات والتصنيفات'), findsOneWidget);
      expect(find.byIcon(Icons.category_rounded), findsOneWidget);
      expect(find.text('شجرة تصنيفات متعددة المستويات (رئيسية وفرعية)'),
          findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.categories()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Product Categories & Hierarchy'), findsOneWidget);
    });

    testWidgets('renders financialReports feature view in Arabic and English',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.financialReports()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('التقارير المالية والقوائم الختامية'), findsOneWidget);
      expect(find.byIcon(Icons.analytics_rounded), findsOneWidget);
      expect(find.text('قائمة الدخل والأرباح والخسائر الفورية (P&L)'),
          findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.financialReports()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Financial Reports & Statements'), findsOneWidget);
    });

    testWidgets('renders chartOfAccounts feature view in Arabic and English',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.chartOfAccounts()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('دليل الحسابات والشجرة المحاسبية'), findsOneWidget);
      expect(find.byIcon(Icons.account_tree_rounded), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.chartOfAccounts()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chart of Accounts'), findsOneWidget);
    });

    testWidgets('renders journalEntries feature view in Arabic and English',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.journalEntries()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('دفتر اليومية العامة والقيود'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.journalEntries()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('General Journal & Entries'), findsOneWidget);
    });

    testWidgets('renders transactions feature view in Arabic and English',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.transactions()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('المبيعات والمعاملات المالية'), findsOneWidget);
      expect(find.byIcon(Icons.point_of_sale_rounded), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.transactions()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sales & Transactions'), findsOneWidget);
    });

    testWidgets('renders dashboard feature view in Arabic and English',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.dashboard()),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('لوحة التحكم والمؤشرات'), findsOneWidget);
      expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.dashboard()),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accounting Dashboard'), findsOneWidget);
    });

    testWidgets('triggers onBack callback when back button is pressed',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool backPressed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: ComingSoonView.categories(
              onBack: () {
                backPressed = true;
              },
            ),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.text('العودة للرئيسية');
      expect(backButton, findsOneWidget);

      await tester.ensureVisible(backButton);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(backPressed, isTrue);
    });

    testWidgets('renders in Dark Mode without layout overflow',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: ComingSoonView.financialReports()),
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Financial Reports & Statements'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ComingSoonPage Tests', () {
    testWidgets('renders ComingSoonPage.categories with AppBar', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ComingSoonPage.categories(
            showAppBar: true,
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('فئات المنتجات والتصنيفات'), findsNWidgets(2));
    });

    testWidgets('renders ComingSoonPage.dashboard without AppBar',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ComingSoonPage.dashboard(
            showAppBar: false,
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('لوحة التحكم والمؤشرات'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });
  });
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/features/accounting_playground/accounting.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';

Future<void> preview(
  WidgetTester tester,
  PlaygroundController c,
  Size size, {
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  c.configuration
    ..device = PreviewDevice.custom
    ..width = size.width
    ..height = size.height;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: BkTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) => RepaintBoundary(
            key: const ValueKey('golden'),
            child: PreviewFrame(controller: c),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('packages/bokrah_design_system/Somar Sans');
    for (final face in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
      loader.addFont(
        rootBundle.load(
          'packages/bokrah_design_system/assets/fonts/SomarSans-$face.otf',
        ),
      );
    }
    await loader.load();
  });
  test(
    'money is exact, localized, precision-aware and rejects implicit rounding',
    () {
      expect((Money.parse('0.10') + Money.parse('0.20')).minor, 30);
      expect(Money.parse('١٢٫٣٤').minor, 1234);
      expect(() => Money.parse('1.001'), throwsFormatException);
      expect(Money.parse('1.001', precision: 3).minor, 1001);
      expect(
        () => const Money(1) + const Money(1, currency: 'USD'),
        throwsArgumentError,
      );
      expect(const Money(-123456).format(), '(1,234.56 JOD)');
      expect(const Money(123456).format(arabic: true), '١٬٢٣٤٫٥٦ JOD');
      expect(const Money(0).format(dashZero: true), '—');
    },
  );
  test(
    'journal validation, snapshots and posting protect financial invariants',
    () {
      final c = PlaygroundController();
      addTearDown(c.dispose);
      expect(c.validateJournal(false), isNotNull);
      c.journal.description = 'Sales';
      expect(c.validateJournal(false), isNull);
      c.saveDraft();
      c.journal.lines[0].debit = '100.01';
      expect(c.savedDraft!.lines[0].debit, '100.00');
      expect(c.postJournal(), isFalse);
      expect(c.debit.minor - c.credit.minor, 1);
      c.journal.lines[1].credit = '100.01';
      expect(c.postJournal(), isTrue);
      c.cancelJournal();
      expect(c.journalPosted, isFalse);
      c.journal.description = 'Invalid';
      c.journal.lines[0].debit = 'NaN';
      expect(c.validateJournal(true), contains('منزلتين'));
    },
  );
  test(
    'transactions combine all filters, sorting, paging, approval and period data',
    () {
      final c = PlaygroundController();
      addTearDown(c.dispose);
      final originalRevenue = c.revenue.minor;
      c
        ..query = 'Restaurant'
        ..status = 'pending'
        ..type = 'income'
        ..from = DateTime(2026, 1, 5)
        ..to = DateTime(2026, 1, 15)
        ..sortColumn = 1
        ..ascending = false;
      expect(c.filtered.map((t) => t.id), [
        'TX-01-012',
        'TX-01-008',
        'TX-01-004',
      ]);
      c.selected.add(c.filtered.first.id);
      c.approveSelected();
      expect(c.filtered.length, 2);
      c.loadPeriod('branch', 1);
      expect(c.revenue.minor, isNot(originalRevenue));
      c.reset();
      expect(c.filtered.length, 24);
      expect(c.paged.length, 6);
      expect(c.pages, 4);
    },
  );
  test('mock invoices and financial statements reconcile', () {
    for (final i in AccountingMockData.invoices) {
      expect(i.total.minor, i.subtotal.minor - i.discount.minor + i.tax.minor);
      expect(i.due.minor, i.total.minor - i.paid.minor);
    }
    final c = PlaygroundController();
    addTearDown(c.dispose);
    final reports = AccountingMockData.reports(c.revenue, c.expenses);
    expect(
      reports[0].rows.take(2).fold(0, (s, r) => s + r.current.minor),
      reports[0].rows.skip(2).fold(0, (s, r) => s + r.current.minor),
    );
    expect(reports[2].rows[0].current.minor, reports[2].rows[1].current.minor);
    expect(
      reports[3].rows.last.current.minor,
      190000 + c.revenue.minor - c.expenses.minor,
    );
  });
  testWidgets(
    'all eight layouts fit narrow RTL, large text, tablet and desktop',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final size in [
        const Size(320, 640),
        const Size(768, 1024),
        const Size(1280, 800),
      ]) {
        for (final layout in AccountingLayout.values) {
          final c = PlaygroundController();
          c.configuration
            ..layout = layout
            ..arabic = size.width == 320
            ..stickyFooter = true;
          await preview(tester, c, size, scale: size.width == 320 ? 2 : 1);
          expect(tester.takeException(), isNull, reason: '$layout $size');
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        }
      }
    },
  );
  testWidgets(
    'shell navigation, collapse, RTL, theme, density and preview states update',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = PlaygroundController();
      addTearDown(c.dispose);
      await preview(tester, c, const Size(1280, 800));
      await tester.tap(find.byTooltip('Collapse sidebar'));
      await tester.pumpAndSettle();
      expect(c.configuration.collapsed, isTrue);
      await tester.tap(find.byTooltip('Journal Entry'));
      await tester.pumpAndSettle();
      expect(c.configuration.layout, AccountingLayout.journal);
      c.update(() {
        c.configuration
          ..arabic = true
          ..appearance = PreviewAppearance.dark
          ..compact = true;
      });
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(AccountingAppShell));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(Theme.of(context).visualDensity, VisualDensity.compact);
      c.update(() => c.configuration.dataState = PreviewState.empty);
      await tester.pumpAndSettle();
      expect(find.byType(AppEmptyState), findsOneWidget);
      c.update(() => c.configuration.dataState = PreviewState.error);
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorState), findsOneWidget);
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();
      expect(c.configuration.dataState, PreviewState.populated);
      c.update(() => c.configuration.dataState = PreviewState.loading);
      await tester.pump();
      expect(find.byType(AppLoadingState), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'configuration device selector changes actual viewport and reset restores defaults',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1500, 950));
      await tester.pumpWidget(const AccountingPlaygroundApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desktop · 1280 × 800'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mobile · 390 × 844').last);
      await tester.pumpAndSettle();
      final frame = tester.widget<PreviewFrame>(find.byType(PreviewFrame));
      expect(frame.controller.configuration.viewport, const Size(390, 844));
      expect(find.byType(AppBottomNavigation), findsOneWidget);
      await tester.tap(find.byTooltip('Reset configuration'));
      await tester.pumpAndSettle();
      expect(frame.controller.configuration.device, PreviewDevice.desktop);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('journal UI adds lines and explains an unbalanced posting', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = PlaygroundController();
    addTearDown(c.dispose);
    c.configuration.layout = AccountingLayout.journal;
    await preview(tester, c, const Size(1000, 1400));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Journal description'),
      'Lunch sales',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Debit 1'),
      '99.99',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Post entry'));
    await tester.tap(find.text('Post entry'));
    await tester.pump();
    expect(c.journalPosted, isFalse);
    expect(c.journalMessage, contains('balance'));
    await tester.ensureVisible(find.text('Add entry row'));
    await tester.tap(find.text('Add entry row'));
    await tester.pump();
    expect(c.journal.lines.length, 3);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'inspector copy emits the real API and all layout examples analyze',
    (tester) async {
      final c = PlaygroundController();
      addTearDown(c.dispose);
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlaygroundInspector(controller: c)),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Copy Code'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Copy Code'));
      await tester.pump();
      expect(clipboard, contains('PreviewFrame(controller: controller)'));
      final dir = Directory('test/accounting_examples');
      const update = bool.fromEnvironment('UPDATE_ACCOUNTING_EXAMPLES');
      if (update) dir.createSync();
      for (final layout in AccountingLayout.values) {
        c.configuration.layout = layout;
        final file = File('${dir.path}/${layout.name}.dart');
        if (update) file.writeAsStringSync(playgroundCode(c.configuration));
        expect(
          file.readAsStringSync().replaceAll('\r\n', '\n'),
          playgroundCode(c.configuration),
        );
      }
    },
  );
  testWidgets(
    'financial semantics expose a readable amount and native buttons have labels',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const FinancialAmount(amount: Money(12345)),
                BkButton(label: 'Post entry', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('123.45 JOD'), findsWidgets);
      expect(find.bySemanticsLabel('Post entry'), findsOneWidget);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    },
  );
  // Pin visual baselines to Windows rasterization; CI has a dedicated Windows job.
  for (final scenario in [
    ('mobile_light_ltr', const Size(390, 844), false, false, false),
    ('mobile_dark_rtl', const Size(390, 844), true, true, false),
    ('tablet', const Size(768, 1024), false, false, false),
    ('desktop', const Size(1280, 800), false, false, false),
    ('desktop_compact', const Size(1280, 800), false, false, true),
  ]) {
    testWidgets('golden ${scenario.$1}', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = PlaygroundController();
      addTearDown(c.dispose);
      c.configuration
        ..arabic = scenario.$3
        ..appearance = scenario.$4
            ? PreviewAppearance.dark
            : PreviewAppearance.light
        ..compact = scenario.$5;
      await preview(tester, c, scenario.$2);
      await expectLater(
        find.byKey(const ValueKey('golden')),
        matchesGoldenFile('goldens/windows/${scenario.$1}.png'),
      );
    }, skip: !Platform.isWindows);
  }
}

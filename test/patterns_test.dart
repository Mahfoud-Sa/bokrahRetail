import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:bokrah_retail/app/features/design_patterns/design_patterns.dart';

Finder input(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);
Widget app(PatternKind kind) => MaterialApp(
  theme: BkTheme.light(),
  home: PatternDemo(kind: kind, arabic: false),
);
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('infinite scrolling appends and pull-to-refresh completes', (
    tester,
  ) async {
    await tester.pumpWidget(app(PatternKind.lists));
    await tap(tester, find.byType(DropdownButton<String>));
    await tap(tester, find.text('Infinite scroll').last);
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }
    expect(find.text('End of sample list'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 4000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.text('Sample list refreshed.'), findsOneWidget);
    expect(find.text('Sample entry 1 · refresh 1'), findsOneWidget);
  });
  test(
    'query/roles reject invalid mutations and preserve the source order',
    () {
      final source = demoRecords();
      expect(
        queryRecords(
          source,
          category: 'sales',
          sortAmount: true,
        ).map((r) => r.amount),
        [45, 240, 1200],
      );
      expect(source.first.id, 1);
      expect(queryRecords(source, query: ' الغداء ').length, 1);
      expect(canPerform('viewer', 'delete'), false);
      expect(canPerform('cashier', 'update'), true);
      expect(canPerform('owner', 'unknown'), false);
      expect(validDraft(' ', '20'), false);
      expect(validDraft('Lunch', 'Infinity'), false);
      expect(validDraft('الغداء', '42.50'), true);
    },
  );
  testWidgets(
    'CRUD creation, cancellation and confirmed deletion preserve the owner route',
    (tester) async {
      await tester.pumpWidget(app(PatternKind.crud));
      await tester.enterText(input('Record name'), 'Test sale');
      await tester.enterText(input('Sample amount (JOD)'), '42');
      await tap(tester, find.text('Create sample record'));
      expect(find.text('Test sale'), findsOneWidget);
      await tap(tester, find.text('Delete #6'));
      await tap(tester, find.text('Keep record'));
      expect(find.text('Test sale'), findsOneWidget);
      await tap(tester, find.text('Delete #6'));
      await tap(tester, find.text('Confirm sample deletion'));
      expect(find.text('Test sale'), findsNothing);
      expect(find.text('Create sample record'), findsOneWidget);
    },
  );
  testWidgets('multi-step validation keeps the draft when navigating back', (
    tester,
  ) async {
    await tester.pumpWidget(app(PatternKind.forms));
    await tap(tester, find.text('Review form'));
    expect(
      find.text('A name and positive amount are required.'),
      findsOneWidget,
    );
    await tester.enterText(input('Sample entry name'), 'Lunch draft');
    await tester.enterText(input('Sample entry amount'), '42.50');
    await tap(tester, find.text('Review form'));
    await tap(tester, find.text('Back to previous step'));
    expect(
      tester.widget<TextField>(input('Sample entry name')).controller!.text,
      'Lunch draft',
    );
    await tap(tester, find.text('Review form'));
    await tap(tester, find.text('Continue to confirmation'));
    await tap(tester, find.text('Confirm sample form'));
    expect(
      find.text('Confirmed locally. No production record was saved.'),
      findsOneWidget,
    );
  });
  testWidgets(
    'OTP blocks an incorrect sample code before completing the preview',
    (tester) async {
      await tester.pumpWidget(app(PatternKind.authentication));
      await tap(tester, find.byType(DropdownButton<String>));
      await tap(tester, find.text('OTP').last);
      await tester.enterText(input('Sample six-digit code'), '123456');
      await tap(tester, find.text('Continue preview'));
      expect(find.text('Use the sample code 000000.'), findsOneWidget);
      await tester.enterText(input('Sample six-digit code'), '000000');
      await tap(tester, find.text('Continue preview'));
      expect(
        find.text('Preview complete. No real session was created.'),
        findsOneWidget,
      );
    },
  );
  testWidgets('search no-results can reset without losing source records', (
    tester,
  ) async {
    await tester.pumpWidget(app(PatternKind.search));
    await tester.enterText(input('Search sample records'), 'missing');
    await tester.pump();
    expect(find.text('0 matching records'), findsOneWidget);
    await tap(tester, find.text('Reset search'));
    expect(find.text('5 matching records'), findsOneWidget);
  });
  testWidgets('viewer hides administration and disables restricted actions', (
    tester,
  ) async {
    await tester.pumpWidget(app(PatternKind.permissions));
    await tap(tester, find.byType(DropdownButton<String>));
    await tap(tester, find.text('Viewer').last);
    expect(find.text('Owner-only administration panel'), findsNothing);
    final action = tester.widget<BkButton>(
      find.widgetWithText(BkButton, 'Preview restricted deletion'),
    );
    expect(action.onPressed, isNull);
  });
  testWidgets('network retry preserves the edited draft', (tester) async {
    await tester.pumpWidget(app(PatternKind.errors));
    await tap(tester, find.byType(DropdownButton<String>));
    await tap(tester, find.text('Network failure').last);
    await tester.enterText(input('Preserved sample draft'), 'Keep this draft');
    await tap(tester, find.text('Retry sample request'));
    expect(find.text('Sample request recovered'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(input('Preserved sample draft'))
          .controller!
          .text,
      'Keep this draft',
    );
  });
  testWidgets('pagination boundaries and refresh reset the sample list', (
    tester,
  ) async {
    await tester.pumpWidget(app(PatternKind.lists));
    expect(
      tester
          .widget<BkButton>(find.widgetWithText(BkButton, 'Previous list page'))
          .onPressed,
      isNull,
    );
    await tap(tester, find.text('Next list page'));
    expect(find.text('2 / 4'), findsOneWidget);
    await tap(tester, find.text('Refresh sample list'));
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('Sample entry 1 · refresh 1'), findsOneWidget);
  });
  testWidgets('Arabic dashboard fits narrow large-text layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: BkTheme.highContrast(arabic: true),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const PatternDemo(kind: PatternKind.dashboard, arabic: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.text('لوحة المعلومات'))),
      TextDirection.rtl,
    );
  });
}

# Testing

## Commands

```powershell
flutter test                                  # everything
flutter test test/features/companies          # one folder
flutter test test/core/widgets/stat_metric_card_test.dart
flutter test --reporter expanded              # per-test output
flutter analyze                               # static gate
```

Current baseline: **16 tests, all passing**. Treat a drop in count as a deleted test until proven otherwise.

## What exists

```
test/
├── core/widgets/stat_metric_card_test.dart
└── features/companies/
    ├── companies_test.dart
    └── company_card_test.dart
```

Coverage is thin: only recently added widgets and the companies feature. There are no unit tests for cubits, repositories, or routing yet. There is no `integration_test/` directory.

## Pattern for widget tests

Tests are plain `flutter_test`. Wrap the widget in `MaterialApp` + `Scaffold` (the theme is optional; import `AppTheme`/`RetailTheme` when asserting colors). Pump, then assert with `find.text`, `find.byType`, `find.byIcon`.

```dart
testWidgets('renders title and value', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: StatMetricCard(title: '...', value: '42', icon: Icons.stars)),
    ),
  );

  expect(find.text('42'), findsOneWidget);
});
```

Callbacks are asserted by tapping and flipping a captured flag; see `company_card_test.dart` for the example.

## Rules

- New shared widget under `lib/app/core/widgets/` → add a test under `test/core/widgets/`.
- New domain logic (entity math, use case, redirect resolution) → unit test under `test/features/<name>/`. These are the highest-value tests; prefer them over more widget snapshots.
- Test names read as behavior: `renders company details, brands, and items count`, not `test 1`.
- No golden files yet. Don't introduce them casually — they are platform-sensitive and this project is Windows-first.
- No mocking library is installed (`mocktail`, `mockito`, `bloc_test` are absent). Prefer hand-written fakes or pure functions. Adding a dev dependency is fine when justified, but call it out.
- Avoid `pumpAndSettle` on screens with infinite animations; use bounded `pump`.
- Widgets that touch `AppLocalizations.of(context)!` need `localizationsDelegates` and `supportedLocales` in the test harness, or they will throw.

## Before you claim done

1. `flutter analyze` → no new issues.
2. `flutter test` → all pass.
3. If you changed a guarded route, manually trace the three tiers (guest, authenticated without store, authenticated with store) in `routes.dart` — there is no automated redirect test to catch you.

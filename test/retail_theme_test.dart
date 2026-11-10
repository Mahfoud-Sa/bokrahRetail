import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/home/side_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Official Bokra Retail Modern Cobalt + Orange Brand Palette', () {
    test('verifies primary brand colors match exact hex values', () {
      expect(AppTheme.deepCobalt, const Color(0xFF243B70));
      expect(AppTheme.actionBlue, const Color(0xFF315FC7));
      expect(AppTheme.brightBlue, const Color(0xFF4778E6));
      expect(AppTheme.warmOrange, const Color(0xFFF29D38));
      expect(AppTheme.deepOrange, const Color(0xFFE58A1F));
      expect(AppTheme.paleOrange, const Color(0xFFFFF1DD));
    });

    test('verifies neutral colors match exact hex values', () {
      expect(AppTheme.mainBackground, const Color(0xFFF4F6FA));
      expect(AppTheme.surface, const Color(0xFFFFFFFF));
      expect(AppTheme.subtleSurface, const Color(0xFFE9EEF7));
      expect(AppTheme.border, const Color(0xFFD9E1EE));
      expect(AppTheme.primaryText, const Color(0xFF172033));
      expect(AppTheme.secondaryText, const Color(0xFF526079));
      expect(AppTheme.mutedText, const Color(0xFF64748B));
    });

    test('verifies semantic colors match exact hex values', () {
      expect(AppTheme.success, const Color(0xFF15803D));
      expect(AppTheme.warning, const Color(0xFFB45309));
      expect(AppTheme.error, const Color(0xFFB91C1C));
      expect(AppTheme.information, const Color(0xFF1D4ED8));
    });

    test('verifies dark theme tokens match exact hex values', () {
      expect(AppTheme.darkMainBackground, const Color(0xFF0F172A));
      expect(AppTheme.darkSurface, const Color(0xFF172033));
      expect(AppTheme.darkElevatedSurface, const Color(0xFF1E293B));
      expect(AppTheme.darkBorder, const Color(0xFF334155));
      expect(AppTheme.darkPrimaryText, const Color(0xFFF8FAFC));
      expect(AppTheme.darkSecondaryText, const Color(0xFFCBD5E1));
      expect(AppTheme.darkPrimaryAction, const Color(0xFF8FB2FF));
      expect(AppTheme.darkOrangeAccent, const Color(0xFFF7B45C));
    });

    test('verifies sidebar design decisions', () {
      expect(AppTheme.sidebarBackground, const Color(0xFF243B70));
      expect(AppTheme.sidebarSelected, const Color(0xFF315FC7));
      expect(AppTheme.sidebarText, Colors.white);
      expect(AppTheme.sidebarIcon, Colors.white);
    });
  });

  group('RetailTheme Light and Dark Builders', () {
    test('RetailTheme.light configures light mode according to specifications', () {
      final lightTheme = RetailTheme.light();

      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, AppTheme.mainBackground);
      expect(lightTheme.colorScheme.primary, AppTheme.actionBlue);
      expect(lightTheme.colorScheme.onPrimary, Colors.white);
      expect(lightTheme.colorScheme.surface, AppTheme.surface);
      expect(lightTheme.colorScheme.onSurface, AppTheme.primaryText);
      expect(lightTheme.colorScheme.onSurfaceVariant, AppTheme.secondaryText);
      expect(lightTheme.colorScheme.outline, AppTheme.border);
      expect(lightTheme.colorScheme.error, AppTheme.error);

      // Verify ThemeExtension
      final ext = lightTheme.extension<RetailColorsExtension>();
      expect(ext, isNotNull);
      expect(ext!.deepCobalt, AppTheme.deepCobalt);
      expect(ext.actionBlue, AppTheme.actionBlue);
      expect(ext.warmOrange, AppTheme.warmOrange);
      expect(ext.sidebarBackground, AppTheme.deepCobalt);
    });

    test('RetailTheme.dark configures complete dark mode according to specifications', () {
      final darkTheme = RetailTheme.dark();

      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, AppTheme.darkMainBackground);
      expect(darkTheme.colorScheme.surface, AppTheme.darkSurface);
      expect(darkTheme.colorScheme.onSurface, AppTheme.darkPrimaryText);
      expect(darkTheme.colorScheme.onSurfaceVariant, AppTheme.darkSecondaryText);
      expect(darkTheme.colorScheme.outline, AppTheme.darkBorder);
      expect(darkTheme.colorScheme.primary, AppTheme.darkPrimaryAction);
      expect(darkTheme.colorScheme.secondary, AppTheme.darkOrangeAccent);
      expect(darkTheme.colorScheme.error, AppTheme.darkError);

      // Verify ThemeExtension
      final ext = darkTheme.extension<RetailColorsExtension>();
      expect(ext, isNotNull);
      expect(ext!.sidebarBackground, AppTheme.deepCobalt);
      expect(ext.actionBlue, AppTheme.darkPrimaryAction);
      expect(ext.warmOrange, AppTheme.darkOrangeAccent);
    });
  });

  group('SidebarItem Widget Rendering & Contrast', () {
    testWidgets('renders SidebarItem in unselected state with white text on deep cobalt', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: RetailTheme.light(),
          home: Scaffold(
            backgroundColor: AppTheme.sidebarBackground,
            body: SidebarItem(
              icon: Icons.dashboard_outlined,
              label: 'لوحة التحكم',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final textFinder = find.text('لوحة التحكم');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, isNotNull);
      // Contrast check: text is high-contrast white on #243B70
      final color = textWidget.style!.color!;
      expect(color.r > 0.8 && color.g > 0.8 && color.b > 0.8, isTrue);
    });

    testWidgets('renders SidebarItem in selected state with Action Blue background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: RetailTheme.light(),
          home: Scaffold(
            backgroundColor: AppTheme.sidebarBackground,
            body: SidebarItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final materialFinder = find.descendant(
        of: find.byType(SidebarItem),
        matching: find.byWidgetPredicate(
          (w) => w is Material && w.color == AppTheme.actionBlue,
        ),
      );
      expect(materialFinder, findsOneWidget);

      final textFinder = find.text('Dashboard');
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, Colors.white);
      expect(textWidget.style?.fontWeight, FontWeight.w600);
    });
  });
}


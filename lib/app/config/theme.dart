import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:flutter/material.dart';

/// Official Bokra Retail Brand Identity: Modern Cobalt + Orange.
///
/// Centralized palette, semantic tokens, theme extensions, and light/dark theme builders.
abstract final class AppTheme {
  // --- Primary Brand Colors ---
  /// Deep Cobalt: Sidebar, brand identity, important headings.
  static const Color deepCobalt = Color(0xFF243B70);

  /// Action Blue: Primary buttons, links, interactive elements.
  static const Color actionBlue = Color(0xFF315FC7);

  /// Bright Blue: Secondary highlights, charts, visual indicators.
  static const Color brightBlue = Color(0xFF4778E6);

  /// Warm Orange: Highlights, badges, important accents.
  static const Color warmOrange = Color(0xFFF29D38);

  /// Deep Orange: Orange hover and active states.
  static const Color deepOrange = Color(0xFFE58A1F);
  static const Color deepOrangeLight = paleOrange;
  static const Color deepOrangeHover = deepOrange;
  static const Color deepOrangeGradientEnd = deepCobalt;

  /// Pale Orange: Subtle accent backgrounds.
  static const Color paleOrange = Color(0xFFFFF1DD);

  // --- Neutral Colors (Light Mode) ---
  /// Main application background.
  static const Color mainBackground = Color(0xFFF4F6FA);

  /// Cards, dialogs, forms.
  static const Color surface = Color(0xFFFFFFFF);

  /// Secondary surfaces.
  static const Color subtleSurface = Color(0xFFE9EEF7);

  /// Borders and dividers.
  static const Color border = Color(0xFFD9E1EE);

  /// Main text.
  static const Color primaryText = Color(0xFF172033);

  /// Supporting text.
  static const Color secondaryText = Color(0xFF526079);

  /// Hints and metadata.
  static const Color mutedText = Color(0xFF64748B);

  // --- Semantic Colors (Light Mode) ---
  static const Color success = Color(0xFF15803D);
  static const Color successSurface = Color(0xFFE7F7ED);

  static const Color warning = Color(0xFFB45309);
  static const Color warningSurface = Color(0xFFFFF1DD);

  static const Color error = Color(0xFFB91C1C);
  static const Color errorSurface = Color(0xFFFEE2E2);

  static const Color information = Color(0xFF1D4ED8);
  static const Color informationSurface = Color(0xFFEFF6FF);

  // --- Dark Theme Tokens ---
  static const Color darkMainBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF172033);
  static const Color darkElevatedSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkPrimaryText = Color(0xFFF8FAFC);
  static const Color darkSecondaryText = Color(0xFFCBD5E1);
  static const Color darkMutedText = Color(0xFF94A3B8);
  static const Color darkPrimaryAction = Color(0xFF8FB2FF);
  static const Color darkOrangeAccent = Color(0xFFF7B45C);

  static const Color darkSuccess = Color(0xFF22C55E);
  static const Color darkSuccessSurface = Color(0xFF14532D);

  static const Color darkWarning = Color(0xFFF59E0B);
  static const Color darkWarningSurface = Color(0xFF452A0A);

  static const Color darkError = Color(0xFFEF4444);
  static const Color darkErrorSurface = Color(0xFF451010);

  static const Color darkInformation = Color(0xFF3B82F6);
  static const Color darkInformationSurface = Color(0xFF172E54);

  // --- Sidebar Design Tokens ---
  static const Color sidebarBackground = deepCobalt; // #243B70
  static const Color sidebarText = Colors.white;
  static const Color sidebarTextMuted = Color(0xCCFFFFFF); // 80% white
  static const Color sidebarSelected = actionBlue; // #315FC7
  static const Color sidebarHover = Color(0x1FFFFFFF); // 12% white
  static const Color sidebarIcon = Colors.white;
  static const Color sidebarBorder = Color(0x26FFFFFF); // 15% white

  // --- Common Geometry & Spacing ---
  static const double radiusInput = 10.0;
  static const double radiusButton = 10.0;
  static const double radiusCard = 14.0;
  static const double controlHeight = 44.0;

  // --- Backward-compatible aliases for smooth migration ---
  static const Color primary = actionBlue;
  static const Color secondary = warmOrange;
  static const Color white = surface;
  static const Color canvas = mainBackground;
  static const Color forestGreen = deepCobalt;
  static const Color warmAmber = warmOrange;
  static const Color creamBackground = mainBackground;
  static const Color creamSurface = surface;
  static const Color creamInputFill = subtleSurface;
  static const Color creamCard = surface;
  static const Color textDarkBrown = primaryText;
  static const Color textMediumBrown = secondaryText;
  static const Color textMutedBrown = mutedText;
  static const Color borderWarm = border;
  static const Color borderWarmActive = actionBlue;
  static const Color shadowWarm = Color(0x14243B70);
  static const Color errorRed = error;
  static const Color errorBackground = errorSurface;
  static const Color successGreen = success;
  static const Color successBackground = successSurface;
}

/// Custom token bridge to provide design-system compatibility
class RetailBkThemeTokens extends BkThemeTokens {
  final Map<String, Color> _colors;
  const RetailBkThemeTokens(super.mode, this._colors);

  @override
  Map<String, Color> get colors => _colors;

  @override
  BkThemeTokens copyWith({String? mode}) =>
      RetailBkThemeTokens(mode ?? this.mode, _colors);
}

/// Semantic ThemeExtension for Bokra Retail
class RetailColorsExtension extends ThemeExtension<RetailColorsExtension> {
  final Color deepCobalt;
  final Color actionBlue;
  final Color brightBlue;
  final Color warmOrange;
  final Color deepOrange;
  final Color paleOrange;
  final Color subtleSurface;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color information;
  final Color successSurface;
  final Color warningSurface;
  final Color errorSurface;
  final Color informationSurface;
  final Color sidebarBackground;
  final Color sidebarText;
  final Color sidebarSelected;

  const RetailColorsExtension({
    required this.deepCobalt,
    required this.actionBlue,
    required this.brightBlue,
    required this.warmOrange,
    required this.deepOrange,
    required this.paleOrange,
    required this.subtleSurface,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.information,
    required this.successSurface,
    required this.warningSurface,
    required this.errorSurface,
    required this.informationSurface,
    required this.sidebarBackground,
    required this.sidebarText,
    required this.sidebarSelected,
  });

  static const RetailColorsExtension light = RetailColorsExtension(
    deepCobalt: AppTheme.deepCobalt,
    actionBlue: AppTheme.actionBlue,
    brightBlue: AppTheme.brightBlue,
    warmOrange: AppTheme.warmOrange,
    deepOrange: AppTheme.deepOrange,
    paleOrange: AppTheme.paleOrange,
    subtleSurface: AppTheme.subtleSurface,
    border: AppTheme.border,
    success: AppTheme.success,
    warning: AppTheme.warning,
    error: AppTheme.error,
    information: AppTheme.information,
    successSurface: AppTheme.successSurface,
    warningSurface: AppTheme.warningSurface,
    errorSurface: AppTheme.errorSurface,
    informationSurface: AppTheme.informationSurface,
    sidebarBackground: AppTheme.sidebarBackground,
    sidebarText: AppTheme.sidebarText,
    sidebarSelected: AppTheme.sidebarSelected,
  );

  static const RetailColorsExtension dark = RetailColorsExtension(
    deepCobalt: AppTheme.deepCobalt,
    actionBlue: AppTheme.darkPrimaryAction,
    brightBlue: AppTheme.brightBlue,
    warmOrange: AppTheme.darkOrangeAccent,
    deepOrange: AppTheme.deepOrange,
    paleOrange: AppTheme.darkWarningSurface,
    subtleSurface: AppTheme.darkElevatedSurface,
    border: AppTheme.darkBorder,
    success: AppTheme.darkSuccess,
    warning: AppTheme.darkWarning,
    error: AppTheme.darkError,
    information: AppTheme.darkInformation,
    successSurface: AppTheme.darkSuccessSurface,
    warningSurface: AppTheme.darkWarningSurface,
    errorSurface: AppTheme.darkErrorSurface,
    informationSurface: AppTheme.darkInformationSurface,
    sidebarBackground: AppTheme.sidebarBackground,
    sidebarText: AppTheme.sidebarText,
    sidebarSelected: AppTheme.sidebarSelected,
  );

  @override
  RetailColorsExtension copyWith({
    Color? deepCobalt,
    Color? actionBlue,
    Color? brightBlue,
    Color? warmOrange,
    Color? deepOrange,
    Color? paleOrange,
    Color? subtleSurface,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
    Color? information,
    Color? successSurface,
    Color? warningSurface,
    Color? errorSurface,
    Color? informationSurface,
    Color? sidebarBackground,
    Color? sidebarText,
    Color? sidebarSelected,
  }) {
    return RetailColorsExtension(
      deepCobalt: deepCobalt ?? this.deepCobalt,
      actionBlue: actionBlue ?? this.actionBlue,
      brightBlue: brightBlue ?? this.brightBlue,
      warmOrange: warmOrange ?? this.warmOrange,
      deepOrange: deepOrange ?? this.deepOrange,
      paleOrange: paleOrange ?? this.paleOrange,
      subtleSurface: subtleSurface ?? this.subtleSurface,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      information: information ?? this.information,
      successSurface: successSurface ?? this.successSurface,
      warningSurface: warningSurface ?? this.warningSurface,
      errorSurface: errorSurface ?? this.errorSurface,
      informationSurface: informationSurface ?? this.informationSurface,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarText: sidebarText ?? this.sidebarText,
      sidebarSelected: sidebarSelected ?? this.sidebarSelected,
    );
  }

  @override
  RetailColorsExtension lerp(ThemeExtension<RetailColorsExtension>? other, double t) {
    if (other is! RetailColorsExtension) return this;
    return RetailColorsExtension(
      deepCobalt: Color.lerp(deepCobalt, other.deepCobalt, t)!,
      actionBlue: Color.lerp(actionBlue, other.actionBlue, t)!,
      brightBlue: Color.lerp(brightBlue, other.brightBlue, t)!,
      warmOrange: Color.lerp(warmOrange, other.warmOrange, t)!,
      deepOrange: Color.lerp(deepOrange, other.deepOrange, t)!,
      paleOrange: Color.lerp(paleOrange, other.paleOrange, t)!,
      subtleSurface: Color.lerp(subtleSurface, other.subtleSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      information: Color.lerp(information, other.information, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      errorSurface: Color.lerp(errorSurface, other.errorSurface, t)!,
      informationSurface: Color.lerp(informationSurface, other.informationSurface, t)!,
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      sidebarText: Color.lerp(sidebarText, other.sidebarText, t)!,
      sidebarSelected: Color.lerp(sidebarSelected, other.sidebarSelected, t)!,
    );
  }
}

extension RetailThemeBuildContext on BuildContext {
  RetailColorsExtension get retailColors =>
      Theme.of(this).extension<RetailColorsExtension>() ?? RetailColorsExtension.light;
}

/// Centralized Retail Theme Factory
abstract final class RetailTheme {
  // Brand color accessors matching specifications
  static const deepCobalt = AppTheme.deepCobalt;
  static const actionBlue = AppTheme.actionBlue;
  static const brightBlue = AppTheme.brightBlue;
  static const warmOrange = AppTheme.warmOrange;
  static const deepOrange = AppTheme.deepOrange;
  static const paleOrange = AppTheme.paleOrange;

  static const mainBackground = AppTheme.mainBackground;
  static const surface = AppTheme.surface;
  static const subtleSurface = AppTheme.subtleSurface;
  static const border = AppTheme.border;
  static const primaryText = AppTheme.primaryText;
  static const secondaryText = AppTheme.secondaryText;
  static const mutedText = AppTheme.mutedText;

  static const success = AppTheme.success;
  static const warning = AppTheme.warning;
  static const error = AppTheme.error;
  static const information = AppTheme.information;

  // Aliases for RetailWorkspace & legacy calls
  static const forest = deepCobalt;
  static const amber = warmOrange;
  static const canvas = mainBackground;
  static const white = surface;

  static Map<String, Color> _buildBkTokensMap(bool isDark) {
    if (isDark) {
      return {
        'background': AppTheme.darkMainBackground,
        'surface': AppTheme.darkSurface,
        'surfaceAlt': AppTheme.darkElevatedSurface,
        'text': AppTheme.darkPrimaryText,
        'muted': AppTheme.darkMutedText,
        'primary': AppTheme.darkPrimaryAction,
        'primaryHover': AppTheme.brightBlue,
        'onPrimary': AppTheme.darkSurface,
        'border': AppTheme.darkBorder,
        'controlBorder': AppTheme.darkBorder,
        'focus': AppTheme.darkPrimaryAction,
        'success': AppTheme.darkSuccess,
        'onSuccess': Colors.white,
        'successSurface': AppTheme.darkSuccessSurface,
        'warning': AppTheme.darkWarning,
        'onWarning': Colors.black,
        'warningSurface': AppTheme.darkWarningSurface,
        'danger': AppTheme.darkError,
        'onDanger': Colors.white,
        'dangerSurface': AppTheme.darkErrorSurface,
        'info': AppTheme.darkInformation,
        'onInfo': Colors.white,
        'infoSurface': AppTheme.darkInformationSurface,
        'secondary': AppTheme.darkOrangeAccent,
        'onSecondary': Colors.black,
        'secondarySurface': AppTheme.darkWarningSurface,
        'accent': AppTheme.darkOrangeAccent,
        'onAccent': Colors.black,
        'accentSurface': AppTheme.darkWarningSurface,
        'neutral': AppTheme.darkSecondaryText,
        'onNeutral': Colors.white,
      };
    }
    return {
      'background': AppTheme.mainBackground,
      'surface': AppTheme.surface,
      'surfaceAlt': AppTheme.subtleSurface,
      'text': AppTheme.primaryText,
      'muted': AppTheme.mutedText,
      'primary': AppTheme.actionBlue,
      'primaryHover': AppTheme.deepCobalt,
      'onPrimary': Colors.white,
      'border': AppTheme.border,
      'controlBorder': AppTheme.border,
      'focus': AppTheme.brightBlue,
      'success': AppTheme.success,
      'onSuccess': Colors.white,
      'successSurface': AppTheme.successSurface,
      'warning': AppTheme.warning,
      'onWarning': Colors.white,
      'warningSurface': AppTheme.warningSurface,
      'danger': AppTheme.error,
      'onDanger': Colors.white,
      'dangerSurface': AppTheme.errorSurface,
      'info': AppTheme.information,
      'onInfo': Colors.white,
      'infoSurface': AppTheme.informationSurface,
      'secondary': AppTheme.warmOrange,
      'onSecondary': Colors.white,
      'secondarySurface': AppTheme.paleOrange,
      'accent': AppTheme.warmOrange,
      'onAccent': Colors.white,
      'accentSurface': AppTheme.paleOrange,
      'neutral': AppTheme.secondaryText,
      'onNeutral': Colors.white,
    };
  }

  /// Builds the official Light Theme (Default)
  static ThemeData light({bool arabic = false}) {
    final base = BkTheme.light(arabic: arabic);
    final scheme = base.colorScheme.copyWith(
      primary: AppTheme.actionBlue,
      onPrimary: Colors.white,
      primaryContainer: AppTheme.subtleSurface,
      onPrimaryContainer: AppTheme.deepCobalt,
      secondary: AppTheme.warmOrange,
      onSecondary: Colors.white,
      secondaryContainer: AppTheme.paleOrange,
      onSecondaryContainer: AppTheme.deepOrange,
      tertiary: AppTheme.brightBlue,
      onTertiary: Colors.white,
      surface: AppTheme.surface,
      onSurface: AppTheme.primaryText,
      onSurfaceVariant: AppTheme.secondaryText,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppTheme.subtleSurface,
      surfaceContainer: AppTheme.mainBackground,
      surfaceContainerHigh: AppTheme.subtleSurface,
      surfaceContainerHighest: const Color(0xFFDFE6F2),
      outline: AppTheme.border,
      outlineVariant: AppTheme.border,
      error: AppTheme.error,
      onError: Colors.white,
      errorContainer: AppTheme.errorSurface,
      onErrorContainer: AppTheme.error,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppTheme.mainBackground,
      primaryColor: AppTheme.actionBlue,
      dividerColor: AppTheme.border,
      extensions: [
        RetailBkThemeTokens('light', _buildBkTokensMap(false)),
        RetailColorsExtension.light,
      ],
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.primaryText,
        iconTheme: const IconThemeData(color: AppTheme.actionBlue),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppTheme.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: base.textTheme.titleMedium?.fontFamily,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.border, width: 1),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.actionBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: buttonShape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.actionBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.actionBlue,
          side: const BorderSide(color: AppTheme.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.actionBlue,
          shape: buttonShape,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppTheme.actionBlue,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: const BorderSide(color: AppTheme.actionBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        labelStyle: const TextStyle(color: AppTheme.secondaryText),
        hintStyle: const TextStyle(color: AppTheme.mutedText),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppTheme.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppTheme.subtleSurface),
        headingTextStyle: const TextStyle(
          color: AppTheme.primaryText,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.subtleSurface;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppTheme.subtleSurface.withValues(alpha: 0.5);
          }
          return AppTheme.surface;
        }),
        dataTextStyle: const TextStyle(
          color: AppTheme.primaryText,
          fontSize: 13,
        ),
        dividerThickness: 1,
        horizontalMargin: 16,
        columnSpacing: 24,
      ),
    );
  }

  /// Builds the official Dark Theme
  static ThemeData dark({bool arabic = false}) {
    final base = BkTheme.dark(arabic: arabic);
    final scheme = base.colorScheme.copyWith(
      primary: AppTheme.darkPrimaryAction,
      onPrimary: AppTheme.darkMainBackground,
      primaryContainer: AppTheme.darkElevatedSurface,
      onPrimaryContainer: AppTheme.darkPrimaryText,
      secondary: AppTheme.darkOrangeAccent,
      onSecondary: Colors.black,
      secondaryContainer: AppTheme.darkWarningSurface,
      onSecondaryContainer: AppTheme.darkOrangeAccent,
      tertiary: AppTheme.brightBlue,
      onTertiary: Colors.white,
      surface: AppTheme.darkSurface,
      onSurface: AppTheme.darkPrimaryText,
      onSurfaceVariant: AppTheme.darkSecondaryText,
      surfaceContainerLowest: AppTheme.darkMainBackground,
      surfaceContainerLow: AppTheme.darkElevatedSurface,
      surfaceContainer: AppTheme.darkSurface,
      surfaceContainerHigh: AppTheme.darkElevatedSurface,
      surfaceContainerHighest: const Color(0xFF2D3E57),
      outline: AppTheme.darkBorder,
      outlineVariant: AppTheme.darkBorder,
      error: AppTheme.darkError,
      onError: Colors.white,
      errorContainer: AppTheme.darkErrorSurface,
      onErrorContainer: AppTheme.darkError,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
    );

    return base.copyWith(
      colorScheme: scheme,
      primaryColor: AppTheme.darkPrimaryAction,
      scaffoldBackgroundColor: AppTheme.darkMainBackground,
      dividerColor: AppTheme.darkBorder,
      extensions: [
        RetailBkThemeTokens('dark', _buildBkTokensMap(true)),
        RetailColorsExtension.dark,
      ],
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppTheme.darkSurface,
        foregroundColor: AppTheme.darkPrimaryText,
        iconTheme: const IconThemeData(color: AppTheme.darkPrimaryAction),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppTheme.darkPrimaryText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: base.textTheme.titleMedium?.fontFamily,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppTheme.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.darkBorder, width: 1),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.darkPrimaryAction,
          foregroundColor: AppTheme.darkMainBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: buttonShape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.darkPrimaryAction,
          foregroundColor: AppTheme.darkMainBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.darkPrimaryAction,
          side: const BorderSide(color: AppTheme.darkBorder, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.darkPrimaryAction,
          shape: buttonShape,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppTheme.darkPrimaryAction,
        foregroundColor: AppTheme.darkMainBackground,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: const BorderSide(color: AppTheme.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: const BorderSide(color: AppTheme.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: const BorderSide(color: AppTheme.darkPrimaryAction, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: const BorderSide(color: AppTheme.darkError),
        ),
        labelStyle: const TextStyle(color: AppTheme.darkSecondaryText),
        hintStyle: const TextStyle(color: AppTheme.darkMutedText),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppTheme.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppTheme.darkElevatedSurface),
        headingTextStyle: const TextStyle(
          color: AppTheme.darkPrimaryText,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.darkElevatedSurface;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppTheme.darkElevatedSurface.withValues(alpha: 0.5);
          }
          return AppTheme.darkSurface;
        }),
        dataTextStyle: const TextStyle(
          color: AppTheme.darkPrimaryText,
          fontSize: 13,
        ),
        dividerThickness: 1,
        horizontalMargin: 16,
        columnSpacing: 24,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/cubits/settings_state.dart';

class SettingsLocalDataSource {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';

  final SharedPreferences sharedPreferences;

  SettingsLocalDataSource({required this.sharedPreferences});

  Future<void> cacheThemeMode(ThemeMode themeMode) async {
    await sharedPreferences.setString(_themeKey, themeMode.name);
  }

  Future<void> cacheBkThemeMode(BkThemeMode mode) async {
    await sharedPreferences.setString(_themeKey, mode.name);
  }

  BkThemeMode getBkThemeMode() {
    final themeName = sharedPreferences.getString(_themeKey);
    return switch (themeName) {
      'dark' => BkThemeMode.dark,
      'highContrast' => BkThemeMode.highContrast,
      _ => BkThemeMode.light,
    };
  }

  ThemeMode getThemeMode() {
    final themeName = sharedPreferences.getString(_themeKey);
    return switch (themeName) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.light,
    };
  }

  Future<void> cacheLanguageCode(String languageCode) async {
    await sharedPreferences.setString(_languageKey, languageCode);
  }

  String getLanguageCode() {
    return sharedPreferences.getString(_languageKey) ?? 'ar';
  }
}

import 'package:bokrah_retail/app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:bokrah_retail/app/features/settings/presentation/cubits/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsLocalDataSource localDataSource;

  SettingsCubit({required this.localDataSource})
      : super(SettingsState.initial()) {
    _loadSettings();
  }

  void _loadSettings() {
    final bkTheme = localDataSource.getBkThemeMode();
    final themeMode = switch (bkTheme) {
      BkThemeMode.dark => ThemeMode.dark,
      _ => ThemeMode.light,
    };
    final languageCode = localDataSource.getLanguageCode();
    emit(SettingsState(
      themeMode: themeMode,
      bkThemeMode: bkTheme,
      locale: Locale(languageCode),
    ));
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    final bkMode = themeMode == ThemeMode.dark
        ? BkThemeMode.dark
        : BkThemeMode.light;
    await localDataSource.cacheBkThemeMode(bkMode);
    emit(state.copyWith(themeMode: themeMode, bkThemeMode: bkMode));
  }

  Future<void> updateBkThemeMode(BkThemeMode mode) async {
    await localDataSource.cacheBkThemeMode(mode);
    final themeMode = switch (mode) {
      BkThemeMode.dark => ThemeMode.dark,
      _ => ThemeMode.light,
    };
    emit(state.copyWith(themeMode: themeMode, bkThemeMode: mode));
  }

  void cycleThemeMode() {
    final next = switch (state.bkThemeMode) {
      BkThemeMode.light => BkThemeMode.dark,
      BkThemeMode.dark => BkThemeMode.highContrast,
      BkThemeMode.highContrast => BkThemeMode.light,
    };
    updateBkThemeMode(next);
  }

  Future<void> updateLanguageCode(String languageCode) async {
    await localDataSource.cacheLanguageCode(languageCode);
    emit(state.copyWith(locale: Locale(languageCode)));
  }

  void toggleLanguage() {
    final newLang = state.locale.languageCode == 'ar' ? 'en' : 'ar';
    updateLanguageCode(newLang);
  }
}

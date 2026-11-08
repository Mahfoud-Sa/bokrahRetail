import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum BkThemeMode { light, dark, highContrast }

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final BkThemeMode bkThemeMode;
  final Locale locale;

  const SettingsState({
    required this.themeMode,
    required this.bkThemeMode,
    required this.locale,
  });

  bool get isHighContrast => bkThemeMode == BkThemeMode.highContrast;

  factory SettingsState.initial() {
    return const SettingsState(
      themeMode: ThemeMode.light,
      bkThemeMode: BkThemeMode.light,
      locale: Locale('ar'),
    );
  }

  SettingsState copyWith({
    ThemeMode? themeMode,
    BkThemeMode? bkThemeMode,
    Locale? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      bkThemeMode: bkThemeMode ?? this.bkThemeMode,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [themeMode, bkThemeMode, locale];
}

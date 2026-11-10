import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../settings/presentation/cubits/settings_cubit.dart';
import '../../../settings/presentation/cubits/settings_state.dart';

class StoreHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;

  const StoreHeader({
    super.key,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final bkTheme = context.watch<SettingsCubit>().state.bkThemeMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Toolbar: Language + Theme + Skip to Dashboard
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: Icon(
                  isArabic ? Icons.arrow_back : Icons.arrow_forward,
                  size: 16,
                ),
                label: Text(
                  isArabic ? 'تخطي إلى الرئيسية' : 'Skip to Dashboard',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  try {
                    context.go('/home');
                  } catch (_) {}
                },
              ),
            ),

            // Controls
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Language Pill
                InkWell(
                  onTap: () => context.read<SettingsCubit>().toggleLanguage(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isArabic ? 'English' : 'العربية',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Theme Mode Switcher
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    switch (bkTheme) {
                      BkThemeMode.light => Icons.light_mode_outlined,
                      BkThemeMode.dark => Icons.dark_mode_outlined,
                      BkThemeMode.highContrast => Icons.contrast,
                    },
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => context.read<SettingsCubit>().cycleThemeMode(),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Brand Hero Emblem & Titles (Retail & Store Focus)
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 38,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title ?? (isArabic ? 'للمتاجر بكره' : 'Bokrah for Stores'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle ??
                    (isArabic
                        ? 'إدارة أسهل لمحلك'
                        : 'Easier management for your shop'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Backward compatibility alias
typedef RestaurantHeader = StoreHeader;


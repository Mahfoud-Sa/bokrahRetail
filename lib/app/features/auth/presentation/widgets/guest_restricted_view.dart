import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';

/// A screen view shown when a Guest User attempts to access restricted administrative
/// features (e.g. Users Management or Restaurant Profile).
class GuestRestrictedView extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onBackToDashboard;

  const GuestRestrictedView({
    super.key,
    required this.title,
    required this.description,
    this.onBackToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BkSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BkSpace.xl,
              vertical: BkSpace.xxl,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(BkRadius.xl),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock Badge Icon with glowing container
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_person_outlined,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: BkSpace.lg),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: BkSpace.sm),

                // Description
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: BkSpace.xl),

                // Actions
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(BkRadius.md),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      try {
                        context.go('/login');
                      } catch (_) {
                        Navigator.of(context).pushNamed('/login');
                      }
                    },
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: Text(
                      isArabic ? 'تسجيل الدخول الآن' : 'Sign In Now',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                if (onBackToDashboard != null) ...[
                  const SizedBox(height: BkSpace.sm),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onBackToDashboard,
                      icon: const Icon(Icons.dashboard_outlined, size: 18),
                      label: Text(
                        isArabic
                            ? 'العودة إلى لوحة التحكم'
                            : 'Back to Dashboard',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../initialzation_dependencies.dart';
import '../cubits/store_cubit.dart';
import '../cubits/store_state.dart';

/// Multi-Store Context Switcher Widget.
/// Placed in the navigation header/topBar to allow users with multiple stores
/// to switch active tenant store context and manage tenant stores.
class StoreContextSwitcher extends StatelessWidget {
  final bool isMobile;

  const StoreContextSwitcher({
    super.key,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    StoreCubit? cubit;
    try {
      cubit = context.watch<StoreCubit>();
    } catch (_) {}

    if (cubit == null) {
      if (singelton.isRegistered<StoreCubit>()) {
        try {
          cubit = singelton<StoreCubit>();
        } catch (_) {}
      }
    }

    if (cubit == null) {
      return const SizedBox.shrink();
    }

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return BlocBuilder<StoreCubit, StoreState>(
      bloc: cubit,
      builder: (context, state) {
        if (state is! StoreLoaded || !state.hasStore) {
          return const SizedBox.shrink();
        }

        final activeStore = state.store;
        final stores = state.accessibleStores;
        final hasMultipleStores = stores.length > 1;

        final displayName = isArabic
            ? (activeStore.nameAr.isNotEmpty
                ? activeStore.nameAr
                : activeStore.nameEn)
            : (activeStore.nameEn.isNotEmpty
                ? activeStore.nameEn
                : activeStore.nameAr);

        final role = activeStore.currentUserRole ?? 'Owner';

        return Theme(
          data: theme.copyWith(
            hoverColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
          child: PopupMenuButton<dynamic>(
            tooltip: isArabic ? 'تبديل المتجر النشط' : 'Switch Active Store',
            offset: const Offset(0, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: isMobile ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? 110 : 160,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName.isNotEmpty
                              ? displayName
                              : (isArabic ? 'متجر بكرة' : 'Bokrah Store'),
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildRoleBadge(context, role, isArabic),
                            const SizedBox(width: 4),
                            Text(
                              activeStore.currency,
                              style: TextStyle(
                                fontSize: 9,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (hasMultipleStores) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
            onSelected: (value) {
              if (value == 'add_new') {
                try {
                  context.push('/create-store');
                } catch (_) {
                  context.go('/create-store');
                }
              } else if (value is int) {
                context.read<StoreCubit>().switchActiveStore(value);
              }
            },
            itemBuilder: (ctx) {
              return [
                PopupMenuItem<dynamic>(
                  enabled: false,
                  child: Text(
                    isArabic ? 'المتاجر التابعة لحسابك' : 'Your Accessible Stores',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const PopupMenuDivider(height: 1),
                ...stores.map((s) {
                  final sId = int.tryParse(s.id) ?? 0;
                  final isActive = sId == state.activeStoreId ||
                      (state.activeStoreId == null && s.id == activeStore.id);
                  final sName = isArabic
                      ? (s.nameAr.isNotEmpty ? s.nameAr : s.nameEn)
                      : (s.nameEn.isNotEmpty ? s.nameEn : s.nameAr);
                  final sRole = s.currentUserRole ?? 'Owner';

                  return PopupMenuItem<dynamic>(
                    value: sId,
                    child: Row(
                      children: [
                        Icon(
                          isActive
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sName.isNotEmpty ? sName : s.id,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${s.businessType} • ${s.currency}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildRoleBadge(context, sRole, isArabic),
                      ],
                    ),
                  );
                }),
                const PopupMenuDivider(height: 1),
                PopupMenuItem<dynamic>(
                  value: 'add_new',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_business_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isArabic ? 'إضافة متجر جديد' : 'Add New Store',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(BuildContext context, String role, bool isArabic) {
    Color bg;
    Color fg;
    String label;

    switch (role.toLowerCase()) {
      case 'owner':
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade800;
        label = isArabic ? 'مالك' : 'Owner';
        break;
      case 'manager':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade700;
        label = isArabic ? 'مدير' : 'Manager';
        break;
      case 'staff':
      default:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade700;
        label = isArabic ? 'موظف' : 'Staff';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

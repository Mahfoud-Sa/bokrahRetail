import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_rbac_cubit.dart';
import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';

class CompanyAccess {
  static bool canManage(BuildContext context) {
    try {
      final roles = context.read<AuthCubit>().state.roles;
      if (roles.any((role) => role.toLowerCase().trim() == 'admin')) {
        return true;
      }
    } catch (_) {}

    try {
      if (context.read<SessionCubit>().state.currentOperator?.role ==
          OperatorRole.admin) {
        return true;
      }
    } catch (_) {}

    try {
      final state = context.read<StoreRbacCubit>().state;
      return state.isCurrentMemberOwner ||
          state.can('store.settings.manage') ||
          state.can('store.inventory.manage');
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requireManage(BuildContext context) async {
    if (canManage(context)) return true;
    if (!context.mounted) return false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined, color: AppTheme.error),
              SizedBox(width: 8),
              Text('صلاحيات غير كافية'),
            ],
          ),
          content: const Text(
            'هذه العملية تتطلب صلاحيات مسؤول النظام (Admin) أو مالك المتجر لإضافة وتعديل بيانات الشركات والعلامات التجارية.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.deepCobalt,
              ),
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );
    return false;
  }
}

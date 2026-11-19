import 'package:flutter/material.dart';

/// Declarative UI widget that conditionally renders action buttons, form inputs,
/// or layout sections based on the active operator's store permissions.
///
/// If [isOwner] is true, superuser access is assumed and [child] is always shown.
/// Otherwise, checks whether [userPermissions] contains [requiredPermission] or
/// satisfies [requiredAnyPermissions] / [requiredAllPermissions].
class PermissionGuard extends StatelessWidget {
  final List<String> userPermissions;
  final bool isOwner;
  final String? requiredPermission;
  final List<String>? requiredAnyPermissions;
  final List<String>? requiredAllPermissions;
  final Widget child;
  final Widget fallback;

  const PermissionGuard({
    super.key,
    required this.userPermissions,
    this.isOwner = false,
    this.requiredPermission,
    this.requiredAnyPermissions,
    this.requiredAllPermissions,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  bool get isAuthorized {
    if (isOwner) return true;

    if (requiredPermission != null &&
        !userPermissions.contains(requiredPermission)) {
      return false;
    }

    if (requiredAnyPermissions != null &&
        requiredAnyPermissions!.isNotEmpty &&
        !requiredAnyPermissions!.any(userPermissions.contains)) {
      return false;
    }

    if (requiredAllPermissions != null &&
        requiredAllPermissions!.isNotEmpty &&
        !requiredAllPermissions!.every(userPermissions.contains)) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return isAuthorized ? child : fallback;
  }
}

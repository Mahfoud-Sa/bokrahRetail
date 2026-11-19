import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bokrah_retail/app/common/widgets/permission_guard.dart';

void main() {
  group('PermissionGuard Widget', () {
    testWidgets('renders child when operator is Store Owner even without permissions',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PermissionGuard(
              isOwner: true,
              userPermissions: [],
              requiredPermission: 'store.roles.manage',
              child: Text('Create Role Button'),
            ),
          ),
        ),
      );

      expect(find.text('Create Role Button'), findsOneWidget);
    });

    testWidgets('renders child when member has the required permission',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PermissionGuard(
              isOwner: false,
              userPermissions: ['store.roles.manage', 'store.orders.view'],
              requiredPermission: 'store.roles.manage',
              child: Text('Create Role Button'),
            ),
          ),
        ),
      );

      expect(find.text('Create Role Button'), findsOneWidget);
    });

    testWidgets('renders fallback (hides child) when member lacks permission',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PermissionGuard(
              isOwner: false,
              userPermissions: ['store.orders.view'],
              requiredPermission: 'store.roles.manage',
              fallback: Text('Access Denied Fallback'),
              child: Text('Create Role Button'),
            ),
          ),
        ),
      );

      expect(find.text('Create Role Button'), findsNothing);
      expect(find.text('Access Denied Fallback'), findsOneWidget);
    });

    testWidgets('evaluates requiredAnyPermissions correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PermissionGuard(
              isOwner: false,
              userPermissions: ['store.roles.view'],
              requiredAnyPermissions: ['store.roles.manage', 'store.roles.view'],
              child: Text('View Roles Tab'),
            ),
          ),
        ),
      );

      expect(find.text('View Roles Tab'), findsOneWidget);
    });
  });
}

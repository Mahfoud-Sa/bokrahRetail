import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:bokrah_retail/app/features/users/data/services/users_service.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';
import 'package:bokrah_retail/app/features/users/presentation/pages/users_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('displays users with role badges and opens role selector in dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: UsersPage(),
        ),
      ),
    );

    // Initial loading settles
    await tester.pumpAndSettle();

    // Default seeded admin should be present
    expect(find.text('المدير العام'), findsOneWidget);
    expect(find.text('مسؤول'), findsOneWidget);

    // Tap Add user button
    final addFab = find.byType(FloatingActionButton);
    expect(addFab, findsOneWidget);
    await tester.tap(addFab);
    await tester.pumpAndSettle();

    // Dialog should show canonical roles
    expect(find.text('إضافة مستخدم جديد'), findsOneWidget);
    expect(find.text('الدور:'), findsOneWidget);
    expect(find.text('مسؤول (Admin)'), findsOneWidget);
    expect(find.text('كاشير (Cashier)'), findsOneWidget);
    expect(find.text('محاسب (Accountant)'), findsOneWidget);
  });

  testWidgets('displays active operator badge and guards active operator against deletion', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final activeAdmin = UserEntity(
      id: 1,
      name: 'المدير العام',
      email: 'admin@bokrah.com',
      role: OperatorRole.admin,
    );
    final sessionCubit = SessionCubit(
      usersService: UsersService(),
      initialOperator: activeAdmin,
    );

    await tester.pumpWidget(
      BlocProvider<SessionCubit>.value(
        value: sessionCubit,
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: UsersPage(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Default seeded admin should have 'المشغّل الحالي' badge
    expect(find.text('المشغّل الحالي'), findsOneWidget);

    // Active operator's delete button should have tooltip 'المشغّل الحالي (لا يمكن حذفه)'
    expect(find.byTooltip('المشغّل الحالي (لا يمكن حذفه)'), findsOneWidget);
  });
}

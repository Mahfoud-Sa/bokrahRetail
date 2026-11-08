import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:bokrah_retail/app/features/users/data/services/users_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UsersService and OperatorRole Tests', () {
    test('seeds default admin operator when local storage is empty', () async {
      final service = UsersService();
      final users = await service.getAllUsers();

      expect(users, isNotEmpty);
      expect(users.first.role, equals(OperatorRole.admin));
      expect(users.first.email, equals('admin@bokrah.com'));
    });

    test('migrates legacy stored users with string roles correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final legacyUsersJson = [
        json.encode({
          'id': 101,
          'name': 'Legacy Admin',
          'email': 'admin@legacy.com',
          'roles': ['Admin'],
          'isActive': true,
        }),
        json.encode({
          'id': 102,
          'name': 'Legacy Staff',
          'email': 'staff@legacy.com',
          'roles': ['Staff'],
          'isActive': true,
        }),
      ];
      await prefs.setStringList('users_list', legacyUsersJson);

      final service = UsersService();
      final users = await service.getAllUsers();

      expect(users.length, equals(2));
      expect(users[0].role, equals(OperatorRole.admin));
      expect(users[1].role, equals(OperatorRole.cashier));
    });

    test('persists user with specific role and updates successfully', () async {
      final service = UsersService();
      await service.getAllUsers(); // seed admin

      final cashier = UserEntity(
        name: 'Ahmed Cashier',
        email: 'ahmed@bokrah.com',
        role: OperatorRole.cashier,
      );
      final saved = await service.saveUser(cashier);
      expect(saved, isTrue);

      final users = await service.getAllUsers();
      final found = users.firstWhere((u) => u.email == 'ahmed@bokrah.com');
      expect(found.role, equals(OperatorRole.cashier));

      final updated = UserEntity(
        id: found.id,
        name: 'Ahmed Manager',
        email: 'ahmed@bokrah.com',
        role: OperatorRole.admin,
      );
      await service.updateUser(updated);

      final reloaded = await service.getAllUsers();
      final foundUpdated = reloaded.firstWhere((u) => u.id == found.id);
      expect(foundUpdated.role, equals(OperatorRole.admin));
    });
  });
}

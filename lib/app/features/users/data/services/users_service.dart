import 'dart:convert';
import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsersService {
  static const String _usersKey = 'users_list';

  Future<List<UserEntity>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_usersKey);
    if (list == null || list.isEmpty) {
      final defaultAdmin = UserEntity(
        id: 1,
        name: 'المدير العام',
        email: 'admin@bokrah.com',
        phoneNumber: '+966500000000',
        role: OperatorRole.admin,
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
      );
      await prefs.setStringList(
        _usersKey,
        [json.encode(defaultAdmin.toMap())],
      );
      return [defaultAdmin];
    }
    return list.map((e) => UserEntity.fromMap(json.decode(e))).toList();
  }

  Future<bool> saveUser(UserEntity user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getAllUsers();
      final newUser = UserEntity(
        id: user.id ?? DateTime.now().millisecondsSinceEpoch,
        name: user.name,
        email: user.email,
        phoneNumber: user.phoneNumber,
        address: user.address,
        birthDate: user.birthDate,
        gender: user.gender,
        role: user.role,
        profileImage: user.profileImage,
        isActive: user.isActive,
        createdAt: user.createdAt,
      );
      list.add(newUser);
      await prefs.setStringList(
        _usersKey,
        list.map((e) => json.encode(e.toMap())).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUser(UserEntity user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getAllUsers();
      final index = list.indexWhere((e) => e.id == user.id);
      if (index != -1) {
        list[index] = user;
        await prefs.setStringList(
          _usersKey,
          list.map((e) => json.encode(e.toMap())).toList(),
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getAllUsers();
      list.removeWhere((e) => e.id == id);
      await prefs.setStringList(
        _usersKey,
        list.map((e) => json.encode(e.toMap())).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

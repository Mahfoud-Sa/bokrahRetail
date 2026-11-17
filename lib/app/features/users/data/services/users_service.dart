import 'dart:convert';
import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence service for application users and operators.
///
/// Stores user profiles synchronized from the backend.
/// Does not generate or seed any mock/default admin data.
class UsersService {
  static const String _usersKey = 'users_list';

  /// Retrieves all cached users from local preferences.
  ///
  /// Returns an empty list if no users have been synced or saved from the backend.
  Future<List<UserEntity>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_usersKey);
    if (list == null || list.isEmpty) {
      return [];
    }
    return list.map((e) => UserEntity.fromMap(json.decode(e))).toList();
  }

  /// Saves a user received from the backend or user management.
  ///
  /// If the user already exists (by [id]), their profile is updated.
  /// Otherwise, the new user is appended to the list.
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
        roles: user.roles,
        profileImage: user.profileImage,
        isActive: user.isActive,
        isEmailVerified: user.isEmailVerified,
        isAccountVerified: user.isAccountVerified,
        createdAt: user.createdAt ?? DateTime.now().toIso8601String(),
      );

      final existingIndex = list.indexWhere((e) => e.id == newUser.id);
      if (existingIndex != -1) {
        list[existingIndex] = newUser;
      } else {
        list.add(newUser);
      }

      await prefs.setStringList(
        _usersKey,
        list.map((e) => json.encode(e.toMap())).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Updates an existing user record.
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

  /// Deletes a user record by their [id].
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

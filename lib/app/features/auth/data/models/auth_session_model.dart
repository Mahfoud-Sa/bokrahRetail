import 'dart:convert';
import 'auth_dto.dart';

/// Represents an authenticated user session with tokens, user info, and roles.
class AuthSessionModel {
  final String userId;
  final String phoneNumber;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String? name;
  final String? email;
  final List<String> roles;
  final bool isEmailVerified;
  final bool isAccountVerified;

  const AuthSessionModel({
    required this.userId,
    required this.phoneNumber,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.name,
    this.email,
    this.roles = const [],
    this.isEmailVerified = false,
    this.isAccountVerified = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isRestaurant =>
      roles.any((r) => r.toLowerCase() == 'restaurant');

  factory AuthSessionModel.fromLoginResponse(
    LoginResponse response, {
    String? phoneNumber,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AuthSessionModel(
      userId: response.id.toString(),
      name: response.name,
      email: response.email,
      phoneNumber: phoneNumber ?? '',
      accessToken: response.token,
      refreshToken: refreshToken ?? response.token,
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      roles: response.roles,
      isEmailVerified: response.isEmailVerified,
      isAccountVerified: response.isAccountVerified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      'roles': roles,
      'isEmailVerified': isEmailVerified,
      'isAccountVerified': isAccountVerified,
    };
  }

  factory AuthSessionModel.fromMap(Map<String, dynamic> map) {
    return AuthSessionModel(
      userId: (map['userId'] ?? '').toString(),
      phoneNumber: (map['phoneNumber'] ?? '').toString(),
      accessToken: (map['accessToken'] ?? '').toString(),
      refreshToken: (map['refreshToken'] ?? '').toString(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : DateTime.now().add(const Duration(days: 30)),
      name: map['name'] as String?,
      email: map['email'] as String?,
      roles: (map['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      isAccountVerified: map['isAccountVerified'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthSessionModel.fromJson(String source) =>
      AuthSessionModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

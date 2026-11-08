import 'dart:convert';

/// Represents a phone number item with number and type (e.g. "Mobile").
class PhoneNumberItem {
  final String number;
  final String type;

  const PhoneNumberItem({
    required this.number,
    this.type = 'Mobile',
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'type': type,
      };

  factory PhoneNumberItem.fromJson(Map<String, dynamic> json) =>
      PhoneNumberItem(
        number: json['number'] as String? ?? '',
        type: json['type'] as String? ?? 'Mobile',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneNumberItem &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          type == other.type;

  @override
  int get hashCode => number.hashCode ^ type.hashCode;
}

/// Registration role types supported by backend endpoints.
enum RegistrationRole {
  restaurant,
  customer,
  delivery,
  admin;

  String get endpointPath {
    switch (this) {
      case RegistrationRole.restaurant:
        return '/api/auth/register/restaurant';
      case RegistrationRole.customer:
        return '/api/auth/register/customer';
      case RegistrationRole.delivery:
        return '/api/auth/register/delivery';
      case RegistrationRole.admin:
        return '/api/auth/register/admin';
    }
  }

  String get roleName {
    switch (this) {
      case RegistrationRole.restaurant:
        return 'Restaurant';
      case RegistrationRole.customer:
        return 'Customer';
      case RegistrationRole.delivery:
        return 'Delivery';
      case RegistrationRole.admin:
        return 'Admin';
    }
  }
}

/// Request payload for user/restaurant registration.
/// Endpoint: POST /api/auth/register/{role}
class UserRegisterRequest {
  final String name;
  final DateTime birthDate;
  final String email;
  final String password;
  final String phoneNumber;
  final String? address;
  final List<PhoneNumberItem>? phoneNumbers;

  const UserRegisterRequest({
    required this.name,
    required this.birthDate,
    required this.email,
    required this.password,
    required this.phoneNumber,
    this.address,
    this.phoneNumbers,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birthDate': birthDate.toUtc().toIso8601String(),
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (phoneNumbers != null && phoneNumbers!.isNotEmpty)
        'phoneNumbers': phoneNumbers!.map((p) => p.toJson()).toList(),
    };
  }

  factory UserRegisterRequest.fromJson(Map<String, dynamic> json) {
    return UserRegisterRequest(
      name: json['name'] as String? ?? '',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : DateTime.now(),
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      address: json['address'] as String?,
      phoneNumbers: (json['phoneNumbers'] as List<dynamic>?)
          ?.map((e) => PhoneNumberItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String toRawJson() => json.encode(toJson());

  factory UserRegisterRequest.fromRawJson(String source) =>
      UserRegisterRequest.fromJson(json.decode(source) as Map<String, dynamic>);
}

/// Response returned by registration endpoints.
/// Success Response (200 OK):
/// {
///   "id": 15,
///   "name": "Al-Bustan Restaurant",
///   "email": "restaurant@example.com",
///   "isActive": true,
///   "roles": ["Restaurant"]
/// }
class AuthUserResponse {
  final int id;
  final String name;
  final String email;
  final bool isActive;
  final List<String> roles;

  const AuthUserResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.roles,
  });

  factory AuthUserResponse.fromJson(Map<String, dynamic> json) {
    return AuthUserResponse(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'isActive': isActive,
        'roles': roles,
      };

  String toRawJson() => json.encode(toJson());

  factory AuthUserResponse.fromRawJson(String source) =>
      AuthUserResponse.fromJson(json.decode(source) as Map<String, dynamic>);
}

/// Request payload for user login.
/// Endpoint: POST /api/auth/login
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };

  factory LoginRequest.fromJson(Map<String, dynamic> json) => LoginRequest(
        email: json['email'] as String? ?? '',
        password: json['password'] as String? ?? '',
      );

  String toRawJson() => json.encode(toJson());

  factory LoginRequest.fromRawJson(String source) =>
      LoginRequest.fromJson(json.decode(source) as Map<String, dynamic>);
}

/// Response returned by user login endpoint.
/// Success Response (200 OK):
/// {
///   "id": 15,
///   "name": "Al-Bustan Restaurant",
///   "email": "restaurant@example.com",
///   "isActive": true,
///   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
///   "isEmailVerified": false,
///   "isAccountVerified": false,
///   "roles": ["restaurant"]
/// }
class LoginResponse {
  final int id;
  final String? name;
  final String email;
  final bool isActive;
  final String token;
  final bool isEmailVerified;
  final bool isAccountVerified;
  final List<String> roles;

  const LoginResponse({
    required this.id,
    this.name,
    required this.email,
    required this.isActive,
    required this.token,
    this.isEmailVerified = false,
    this.isAccountVerified = false,
    this.roles = const [],
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String?,
      email: json['email'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      token: json['token'] as String? ?? '',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isAccountVerified: json['isAccountVerified'] as bool? ?? false,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'isActive': isActive,
        'token': token,
        'isEmailVerified': isEmailVerified,
        'isAccountVerified': isAccountVerified,
        'roles': roles,
      };

  String toRawJson() => json.encode(toJson());

  factory LoginResponse.fromRawJson(String source) =>
      LoginResponse.fromJson(json.decode(source) as Map<String, dynamic>);
}

/// Authenticated user session representation
class UserSession {
  final int id;
  final String? name;
  final String email;
  final List<String> roles;
  final bool isEmailVerified;
  final bool isAccountVerified;

  const UserSession({
    required this.id,
    this.name,
    required this.email,
    this.roles = const [],
    this.isEmailVerified = false,
    this.isAccountVerified = false,
  });

  factory UserSession.fromLoginResponse(LoginResponse response) {
    return UserSession(
      id: response.id,
      name: response.name,
      email: response.email,
      roles: response.roles,
      isEmailVerified: response.isEmailVerified,
      isAccountVerified: response.isAccountVerified,
    );
  }

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        id: json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id'].toString()) ?? 0,
        name: json['name'] as String?,
        email: json['email'] as String? ?? '',
        roles: (json['roles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        isEmailVerified: json['isEmailVerified'] as bool? ?? false,
        isAccountVerified: json['isAccountVerified'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (name != null) 'name': name,
        'email': email,
        'roles': roles,
        'isEmailVerified': isEmailVerified,
        'isAccountVerified': isAccountVerified,
      };

  String toRawJson() => json.encode(toJson());

  factory UserSession.fromRawJson(String source) =>
      UserSession.fromJson(json.decode(source) as Map<String, dynamic>);
}


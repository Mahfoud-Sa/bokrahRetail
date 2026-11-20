enum OperatorRole {
  admin,
  cashier,
  accountant;

  String get displayName {
    switch (this) {
      case OperatorRole.admin:
        return 'مسؤول';
      case OperatorRole.cashier:
        return 'كاشير';
      case OperatorRole.accountant:
        return 'محاسب';
    }
  }

  String get nameEn {
    switch (this) {
      case OperatorRole.admin:
        return 'Admin';
      case OperatorRole.cashier:
        return 'Cashier';
      case OperatorRole.accountant:
        return 'Accountant';
    }
  }

  static OperatorRole fromString(String? role) {
    if (role == null) return OperatorRole.cashier;
    final normalized = role.trim().toLowerCase();
    if (normalized == 'admin' ||
        normalized == 'مسؤول' ||
        normalized == 'owner' ||
        normalized == 'store') {
      return OperatorRole.admin;
    }
    if (normalized == 'accountant' || normalized == 'محاسب') {
      return OperatorRole.accountant;
    }
    return OperatorRole.cashier;
  }
}

class UserEntity {
  final int? id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? birthDate;
  final String? gender;
  final OperatorRole role;
  final String? customRoleName;
  final String? profileImage;
  final bool isActive;
  final bool isEmailVerified;
  final bool isAccountVerified;
  final String? createdAt;
  final String? password;

  UserEntity({
    this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.address,
    this.birthDate,
    this.gender,
    this.role = OperatorRole.cashier,
    this.customRoleName,
    List<String>? roles,
    this.profileImage,
    this.isActive = true,
    this.isEmailVerified = false,
    this.isAccountVerified = false,
    this.createdAt,
    this.password,
  }) : _legacyRoles = roles;

  final List<String>? _legacyRoles;

  UserEntity copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    String? birthDate,
    String? gender,
    OperatorRole? role,
    String? customRoleName,
    List<String>? roles,
    String? profileImage,
    bool? isActive,
    bool? isEmailVerified,
    bool? isAccountVerified,
    String? createdAt,
    String? password,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      customRoleName: customRoleName ?? this.customRoleName,
      roles: roles ?? this.roles,
      profileImage: profileImage ?? this.profileImage,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isAccountVerified: isAccountVerified ?? this.isAccountVerified,
      createdAt: createdAt ?? this.createdAt,
      password: password ?? this.password,
    );
  }

  String get displayRoleName {
    if (customRoleName != null && customRoleName!.trim().isNotEmpty) {
      return customRoleName!;
    }
    return role.displayName;
  }

  List<String> get roles {
    final legacy = _legacyRoles;
    if (legacy != null && legacy.isNotEmpty) {
      return legacy;
    }
    if (customRoleName != null && customRoleName!.trim().isNotEmpty) {
      return [customRoleName!];
    }
    return [role.nameEn];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'birthDate': birthDate,
      'gender': gender,
      'role': role.nameEn,
      'customRoleName': customRoleName,
      'roles': roles,
      'profileImage': profileImage,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'isAccountVerified': isAccountVerified,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      if (password != null) 'password': password,
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    OperatorRole resolvedRole = OperatorRole.cashier;
    if (map['role'] != null) {
      resolvedRole = OperatorRole.fromString(map['role'].toString());
    } else if (map['roles'] != null && (map['roles'] as List).isNotEmpty) {
      resolvedRole = OperatorRole.fromString(map['roles'][0].toString());
    }

    final customRole = map['customRoleName']?.toString() ??
        (map['role'] != null &&
                OperatorRole.fromString(map['role'].toString()) ==
                    OperatorRole.cashier &&
                map['role'].toString().toLowerCase() != 'cashier' &&
                map['role'].toString() != 'كاشير'
            ? map['role'].toString()
            : null);

    return UserEntity(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      birthDate: map['birthDate'],
      gender: map['gender'],
      role: resolvedRole,
      customRoleName: customRole,
      profileImage: map['profileImage'],
      isActive: map['isActive'] ?? true,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      isAccountVerified: map['isAccountVerified'] as bool? ?? false,
      createdAt: map['createdAt'],
      password: map['password']?.toString(),
    );
  }
}


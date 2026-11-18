import 'dart:convert';

/// Represents a phone number attached to a user profile.
class ProfilePhoneNumberDto {
  final String number;
  final String type;

  const ProfilePhoneNumberDto({
    required this.number,
    this.type = 'Mobile',
  });

  ProfilePhoneNumberDto copyWith({
    String? number,
    String? type,
  }) {
    return ProfilePhoneNumberDto(
      number: number ?? this.number,
      type: type ?? this.type,
    );
  }

  factory ProfilePhoneNumberDto.fromMap(Map<String, dynamic> map) {
    return ProfilePhoneNumberDto(
      number: map['number']?.toString() ?? '',
      type: map['type']?.toString() ?? 'Mobile',
    );
  }

  factory ProfilePhoneNumberDto.fromJson(dynamic json) {
    if (json is String) {
      return ProfilePhoneNumberDto.fromMap(jsonDecode(json));
    } else if (json is Map<String, dynamic>) {
      return ProfilePhoneNumberDto.fromMap(json);
    } else if (json is Map) {
      return ProfilePhoneNumberDto.fromMap(Map<String, dynamic>.from(json));
    }
    return const ProfilePhoneNumberDto(number: '');
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'type': type,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfilePhoneNumberDto &&
        other.number == number &&
        other.type == type;
  }

  @override
  int get hashCode => number.hashCode ^ type.hashCode;

  @override
  String toString() => 'ProfilePhoneNumberDto(number: $number, type: $type)';
}

/// Data Transfer Object representing the user profile payload.
class UserProfileDto {
  final int? id;
  final String fullName;
  final String email;
  final DateTime? birthDate;
  final List<ProfilePhoneNumberDto> phoneNumbers;
  final String? profilePicture;

  const UserProfileDto({
    this.id,
    required this.fullName,
    required this.email,
    this.birthDate,
    this.phoneNumbers = const [],
    this.profilePicture,
  });

  UserProfileDto copyWith({
    int? id,
    String? fullName,
    String? email,
    DateTime? birthDate,
    List<ProfilePhoneNumberDto>? phoneNumbers,
    String? profilePicture,
  }) {
    return UserProfileDto(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }

  factory UserProfileDto.fromMap(Map<String, dynamic> map) {
    DateTime? parsedDate;
    final rawDate = map['birthDate'];
    if (rawDate != null && rawDate.toString().isNotEmpty) {
      try {
        parsedDate = DateTime.parse(rawDate.toString());
      } catch (_) {
        parsedDate = null;
      }
    }

    final rawList = map['phoneNumbers'];
    final List<ProfilePhoneNumberDto> phones = [];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          phones.add(ProfilePhoneNumberDto.fromMap(item));
        } else if (item is Map) {
          phones.add(ProfilePhoneNumberDto.fromMap(Map<String, dynamic>.from(item)));
        } else if (item is String && item.isNotEmpty) {
          phones.add(ProfilePhoneNumberDto(number: item, type: 'Mobile'));
        }
      }
    }

    // Extract image url if returned in any standard key
    final picture = map['profilePicture']?.toString() ??
        map['profileImage']?.toString() ??
        map['imageUrl']?.toString() ??
        map['pictureUrl']?.toString() ??
        map['image']?.toString();

    final rawId = map['id'] ?? map['userId'];
    final parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    return UserProfileDto(
      id: parsedId,
      fullName: map['fullName']?.toString() ?? map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      birthDate: parsedDate,
      phoneNumbers: phones,
      profilePicture: (picture != null && picture.isNotEmpty) ? picture : null,
    );
  }

  factory UserProfileDto.fromJson(dynamic json) {
    if (json is String) {
      return UserProfileDto.fromMap(jsonDecode(json));
    } else if (json is Map<String, dynamic>) {
      return UserProfileDto.fromMap(json);
    } else if (json is Map) {
      return UserProfileDto.fromMap(Map<String, dynamic>.from(json));
    }
    return const UserProfileDto(fullName: '', email: '');
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'birthDate': birthDate?.toUtc().toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
      'phoneNumbers': phoneNumbers.map((p) => p.toMap()).toList(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileDto &&
        other.fullName == fullName &&
        other.email == email &&
        other.birthDate == birthDate &&
        other.profilePicture == profilePicture;
  }

  @override
  int get hashCode =>
      fullName.hashCode ^
      email.hashCode ^
      birthDate.hashCode ^
      profilePicture.hashCode;

  @override
  String toString() =>
      'UserProfileDto(fullName: $fullName, email: $email, birthDate: $birthDate, phoneNumbers: $phoneNumbers, profilePicture: $profilePicture)';
}

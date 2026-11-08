import 'store_entity.dart';

export 'store_phone_number.dart';

/// Form payload for creating a new store tenant via `POST /api/stores`.
/// Matching ASP.NET Core backend contract:
/// - `name`: Required, 2-120 chars
/// - `description`: Optional, max 500 chars
/// - `phoneNumber`: Optional, valid phone, max 30 chars
/// - `email`: Optional, valid email, max 256 chars
/// - `address`: Optional, max 500 chars
/// - `currencyCode`: Optional, default "JOD", 3-10 chars
/// - `isActive`: Optional, default true
class CreateStoreRequest {
  final String? name;
  final String? nameAr;
  final String? nameEn;
  final String? slogan;
  final String? subtitle;
  final String? businessType;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? phone;
  final List<StorePhoneNumberInput>? phoneNumbers;
  final String? email;
  final String currencyCode;
  final bool isActive;
  final String? googleMapsUrl;
  final double? latitude;
  final double? longitude;
  final String? websiteUrl;
  final String? commercialRegistration;
  final String? taxNumber;
  final String? warrantyPolicy;
  final String? returnPolicy;

  const CreateStoreRequest({
    this.name,
    this.nameAr,
    this.nameEn,
    this.slogan,
    this.subtitle,
    this.businessType,
    this.description,
    this.address,
    this.phoneNumber,
    this.phone,
    this.phoneNumbers,
    this.email,
    this.currencyCode = 'JOD',
    this.isActive = true,
    this.googleMapsUrl,
    this.latitude,
    this.longitude,
    this.websiteUrl,
    this.commercialRegistration,
    this.taxNumber,
    this.warrantyPolicy,
    this.returnPolicy,
  });

  /// The primary effective name for backend submission
  String get effectiveName {
    final cleanName = name?.trim() ?? '';
    if (cleanName.isNotEmpty) return cleanName;
    final cleanNameAr = nameAr?.trim() ?? '';
    if (cleanNameAr.isNotEmpty) return cleanNameAr;
    final cleanNameEn = nameEn?.trim() ?? '';
    if (cleanNameEn.isNotEmpty) return cleanNameEn;
    return '';
  }

  /// Effective primary phone number
  String? get effectivePhone {
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) {
      return phoneNumber!.trim();
    }
    if (phone != null && phone!.trim().isNotEmpty) {
      return phone!.trim();
    }
    if (phoneNumbers != null && phoneNumbers!.isNotEmpty) {
      for (final p in phoneNumbers!) {
        if (p.number.trim().isNotEmpty) return p.number.trim();
      }
    }
    return null;
  }

  /// Business Rule: Name is required and must be between 2 and 120 characters.
  bool get hasValidName {
    final eff = effectiveName;
    return eff.length >= 2 && eff.length <= 120;
  }

  /// Client-side validation against backend constraints
  Map<String, String>? validate() {
    final errors = <String, String>{};
    final effName = effectiveName;
    if (effName.isEmpty) {
      errors['name'] = 'اسم المتجر مطلوب (Store name is required).';
    } else if (effName.length < 2 || effName.length > 120) {
      errors['name'] = 'يجب أن يكون اسم المتجر بين 2 و 120 حرفاً.';
    }

    if (description != null && description!.length > 500) {
      errors['description'] = 'لا يمكن أن يتجاوز الوصف 500 حرف.';
    }

    final p = effectivePhone;
    if (p != null && p.length > 30) {
      errors['phoneNumber'] = 'رقم الهاتف لا يجب أن يتجاوز 30 حرفاً.';
    }

    if (email != null && email!.trim().isNotEmpty) {
      final cleanEmail = email!.trim();
      if (cleanEmail.length > 256) {
        errors['email'] = 'البريد الإلكتروني لا يمكن أن يتجاوز 256 حرفاً.';
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(cleanEmail)) {
        errors['email'] = 'يُرجى إدخال بريد إلكتروني صحيح.';
      }
    }

    if (address != null && address!.length > 500) {
      errors['address'] = 'العنوان لا يمكن أن يتجاوز 500 حرف.';
    }

    if (currencyCode.length < 3 || currencyCode.length > 10) {
      errors['currencyCode'] = 'رمز العملة يجب أن يكون بين 3 و 10 أحرف.';
    }

    return errors.isEmpty ? null : errors;
  }

  factory CreateStoreRequest.fromJson(Map<String, dynamic> json) {
    List<StorePhoneNumberInput>? phones;
    if (json['phoneNumbers'] is List) {
      phones = (json['phoneNumbers'] as List)
          .map((e) => StorePhoneNumberInput.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final directPhone = json['phoneNumber'] as String? ?? json['phone'] as String?;

    return CreateStoreRequest(
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      nameEn: json['nameEn'] as String?,
      slogan: json['slogan'] as String?,
      subtitle: json['subtitle'] as String?,
      businessType:
          json['businessType'] as String? ?? json['cuisineType'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String?,
      phoneNumber: directPhone,
      phone: directPhone,
      phoneNumbers: phones,
      email: json['email'] as String?,
      currencyCode: json['currencyCode'] as String? ?? 'JOD',
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      googleMapsUrl: json['googleMapsUrl'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      websiteUrl: json['websiteUrl'] as String?,
      commercialRegistration: json['commercialRegistration'] as String?,
      taxNumber: json['taxNumber'] as String?,
      warrantyPolicy: json['warrantyPolicy'] as String?,
      returnPolicy: json['returnPolicy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final nameVal = effectiveName;
    final phoneVal = effectivePhone;

    return {
      if (nameVal.isNotEmpty) 'name': nameVal,
      if (nameAr != null && nameAr!.trim().isNotEmpty) 'nameAr': nameAr!.trim(),
      if (nameEn != null && nameEn!.trim().isNotEmpty) 'nameEn': nameEn!.trim(),
      if (slogan != null && slogan!.trim().isNotEmpty) 'slogan': slogan!.trim(),
      if (subtitle != null && subtitle!.trim().isNotEmpty)
        'subtitle': subtitle!.trim(),
      if (businessType != null && businessType!.trim().isNotEmpty)
        'businessType': businessType!.trim(),
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (phoneVal != null && phoneVal.isNotEmpty) 'phoneNumber': phoneVal,
      if (phoneVal != null && phoneVal.isNotEmpty) 'phone': phoneVal,
      if (phoneNumbers != null && phoneNumbers!.isNotEmpty)
        'phoneNumbers': phoneNumbers!.map((p) => p.toJson()).toList(),
      if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
      if (address != null && address!.trim().isNotEmpty)
        'address': address!.trim(),
      'currencyCode': currencyCode,
      'isActive': isActive,
      if (googleMapsUrl != null && googleMapsUrl!.trim().isNotEmpty)
        'googleMapsUrl': googleMapsUrl!.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (websiteUrl != null && websiteUrl!.trim().isNotEmpty)
        'websiteUrl': websiteUrl!.trim(),
      if (commercialRegistration != null &&
          commercialRegistration!.trim().isNotEmpty)
        'commercialRegistration': commercialRegistration!.trim(),
      if (taxNumber != null && taxNumber!.trim().isNotEmpty)
        'taxNumber': taxNumber!.trim(),
      if (warrantyPolicy != null && warrantyPolicy!.trim().isNotEmpty)
        'warrantyPolicy': warrantyPolicy!.trim(),
      if (returnPolicy != null && returnPolicy!.trim().isNotEmpty)
        'returnPolicy': returnPolicy!.trim(),
    };
  }
}

/// DTO for responses returned from `/api/stores` endpoints.
/// Matches ASP.NET Core `StoreResponse`:
/// - `id`: number
/// - `ownerUserId`: number
/// - `name`: string
/// - `description`: string | null
/// - `phoneNumber`: string | null
/// - `email`: string | null
/// - `address`: string | null
/// - `currencyCode`: string
/// - `isActive`: boolean
/// - `createdAtUtc`: string (ISO 8601)
/// - `updatedAtUtc`: string | null
/// - `currentUserRole`: 'Owner' | 'Manager' | 'Staff' | null
class StoreResponseDto {
  final int id;
  final int ownerUserId;
  final String name;
  final String? description;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String currencyCode;
  final bool isActive;
  final String createdAtUtc;
  final String? updatedAtUtc;
  final String? currentUserRole; // 'Owner' | 'Manager' | 'Staff' | null

  // Extended / Legacy fields
  final String? nameAr;
  final String? nameEn;
  final String? slogan;
  final String? subtitle;
  final String? businessType;
  final String? googleMapsUrl;
  final double? latitude;
  final double? longitude;
  final String? websiteUrl;
  final List<StorePhoneNumberInput> phoneNumbers;
  final String? ownerName;

  const StoreResponseDto({
    required this.id,
    required this.ownerUserId,
    required this.name,
    this.description,
    this.phoneNumber,
    this.email,
    this.address,
    this.currencyCode = 'JOD',
    this.isActive = true,
    required this.createdAtUtc,
    this.updatedAtUtc,
    this.currentUserRole,
    this.nameAr,
    this.nameEn,
    this.slogan,
    this.subtitle,
    this.businessType,
    this.googleMapsUrl,
    this.latitude,
    this.longitude,
    this.websiteUrl,
    this.phoneNumbers = const [],
    this.ownerName,
  });

  // Backward compatibility getters
  int get userId => ownerUserId;
  String? get phone => phoneNumber;
  String get createdAt => createdAtUtc;
  String get updatedAt => updatedAtUtc ?? '';

  // Role helpers
  bool get isOwner => currentUserRole?.toLowerCase() == 'owner';
  bool get isManager => currentUserRole?.toLowerCase() == 'manager';
  bool get isStaff => currentUserRole?.toLowerCase() == 'staff';

  factory StoreResponseDto.fromJson(Map<String, dynamic> json) {
    List<StorePhoneNumberInput>? phones;
    if (json['phoneNumbers'] is List) {
      phones = (json['phoneNumbers'] as List)
          .map((e) => StorePhoneNumberInput.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final idVal = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '') ?? 0;

    final ownerIdVal = json['ownerUserId'] is int
        ? json['ownerUserId'] as int
        : (json['userId'] is int
            ? json['userId'] as int
            : int.tryParse(
                    json['ownerUserId']?.toString() ?? json['userId']?.toString() ?? '') ??
                0);

    final phoneVal =
        json['phoneNumber'] as String? ?? json['phone'] as String?;

    final createdUtcVal = json['createdAtUtc'] as String? ??
        json['createdAt'] as String? ??
        DateTime.now().toIso8601String();

    final updatedUtcVal =
        json['updatedAtUtc'] as String? ?? json['updatedAt'] as String?;

    return StoreResponseDto(
      id: idVal,
      ownerUserId: ownerIdVal,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      phoneNumber: phoneVal,
      email: json['email'] as String?,
      address: json['address'] as String?,
      currencyCode: json['currencyCode'] as String? ?? 'JOD',
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      createdAtUtc: createdUtcVal,
      updatedAtUtc: updatedUtcVal,
      currentUserRole: json['currentUserRole'] as String?,
      nameAr: json['nameAr'] as String?,
      nameEn: json['nameEn'] as String?,
      slogan: json['slogan'] as String?,
      subtitle: json['subtitle'] as String?,
      businessType:
          json['businessType'] as String? ?? json['cuisineType'] as String?,
      googleMapsUrl: json['googleMapsUrl'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      websiteUrl: json['websiteUrl'] as String?,
      phoneNumbers: phones ?? const [],
      ownerName: json['ownerName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUserId': ownerUserId,
      'userId': ownerUserId,
      'name': name,
      if (description != null) 'description': description,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (phoneNumber != null) 'phone': phoneNumber,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      'currencyCode': currencyCode,
      'isActive': isActive,
      'createdAtUtc': createdAtUtc,
      'createdAt': createdAtUtc,
      if (updatedAtUtc != null) 'updatedAtUtc': updatedAtUtc,
      if (updatedAtUtc != null) 'updatedAt': updatedAtUtc,
      if (currentUserRole != null) 'currentUserRole': currentUserRole,
      if (nameAr != null) 'nameAr': nameAr,
      if (nameEn != null) 'nameEn': nameEn,
      if (slogan != null) 'slogan': slogan,
      if (subtitle != null) 'subtitle': subtitle,
      if (businessType != null) 'businessType': businessType,
      if (googleMapsUrl != null) 'googleMapsUrl': googleMapsUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
      if (phoneNumbers.isNotEmpty)
        'phoneNumbers': phoneNumbers.map((p) => p.toJson()).toList(),
      if (ownerName != null) 'ownerName': ownerName,
    };
  }

  StoreEntity toEntity() {
    final effectiveNameAr =
        (nameAr != null && nameAr!.trim().isNotEmpty) ? nameAr!.trim() : name;
    final effectiveNameEn =
        (nameEn != null && nameEn!.trim().isNotEmpty) ? nameEn!.trim() : name;

    String primaryPhone = phoneNumber?.trim() ?? '';
    String mobile = '';

    for (final p in phoneNumbers) {
      final t = p.type.toLowerCase();
      if (t == 'mobile' && mobile.isEmpty) {
        mobile = p.number;
      }
      if (primaryPhone.isEmpty) {
        primaryPhone = p.number;
      }
    }
    if (mobile.isEmpty) {
      mobile = primaryPhone;
    }

    final convertedPhones = phoneNumbers
        .map((p) => StorePhoneNumberInput(
              id: p.id,
              number: p.number,
              type: p.type,
            ))
        .toList();

    return StoreEntity(
      id: id.toString(),
      ownerUserId: ownerUserId,
      currentUserRole: currentUserRole,
      isActive: isActive,
      currency: currencyCode,
      nameAr: effectiveNameAr,
      nameEn: effectiveNameEn,
      slogan: slogan ?? 'وجهتكم الأولى للإلكترونيات والأجهزة الذكية',
      subtitle: subtitle ?? 'إلكترونيات وأجهزة ذكية وملحقاتها',
      businessType: businessType ?? subtitle ?? 'إلكترونيات وأجهزة ذكية',
      description: description ??
          'متجر تجزئة متخصص في بيع وصيانة الأجهزة الإلكترونية والهواتف الذكية.',
      street: address ?? '',
      email: email ?? 'info@bokrah-retail.com',
      googleMapsUrl: googleMapsUrl ?? '',
      latitude: latitude,
      longitude: longitude,
      website: websiteUrl ?? '',
      phoneNumber: primaryPhone,
      mobileNumber: mobile,
      phoneNumbers: convertedPhones,
      userId: ownerUserId,
      ownerName: ownerName,
      updatedAt: updatedAtUtc ?? createdAtUtc,
    );
  }
}

/// ASP.NET Core API Error Response contract:
/// `{ message?: string, errors?: Record<string, string[]> }`
class ApiErrorResponse {
  final String? message;
  final Map<String, List<String>>? errors;

  const ApiErrorResponse({
    this.message,
    this.errors,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>>? parsedErrors;
    if (json['errors'] is Map) {
      parsedErrors = (json['errors'] as Map).map((key, val) {
        if (val is List) {
          return MapEntry(
            key.toString(),
            val.map((e) => e.toString()).toList(),
          );
        }
        return MapEntry(key.toString(), [val.toString()]);
      });
    }

    return ApiErrorResponse(
      message: json['message']?.toString() ??
          json['title']?.toString() ??
          json['error']?.toString(),
      errors: parsedErrors,
    );
  }

  /// Extracts single field error if present
  String? fieldError(String fieldName) {
    if (errors == null) return null;
    final key = errors!.keys.firstWhere(
      (k) => k.toLowerCase() == fieldName.toLowerCase(),
      orElse: () => '',
    );
    if (key.isNotEmpty && errors![key] != null && errors![key]!.isNotEmpty) {
      return errors![key]!.join(', ');
    }
    return null;
  }

  /// Formatted error string for dialogs or snackbars
  String get formattedErrorMessage {
    if (errors != null && errors!.isNotEmpty) {
      final buffer = StringBuffer();
      if (message != null && message!.isNotEmpty) {
        buffer.writeln(message);
      }
      errors!.forEach((key, list) {
        buffer.writeln('$key: ${list.join(', ')}');
      });
      return buffer.toString().trim();
    }
    return message ?? 'Validation failed. Please verify the input values.';
  }
}

/// Backward-compatibility alias class
class CreateRestaurantRequest extends CreateStoreRequest {
  const CreateRestaurantRequest({
    super.name,
    super.nameAr,
    super.nameEn,
    super.slogan,
    super.subtitle,
    super.businessType,
    super.description,
    super.address,
    super.phoneNumber,
    super.phone,
    super.phoneNumbers,
    super.email,
    super.currencyCode = 'JOD',
    super.isActive = true,
    super.googleMapsUrl,
    super.latitude,
    super.longitude,
    super.websiteUrl,
    super.commercialRegistration,
    super.taxNumber,
    super.warrantyPolicy,
    super.returnPolicy,
  });

  factory CreateRestaurantRequest.fromJson(Map<String, dynamic> json) {
    final req = CreateStoreRequest.fromJson(json);
    return CreateRestaurantRequest(
      name: req.name,
      nameAr: req.nameAr,
      nameEn: req.nameEn,
      slogan: req.slogan,
      subtitle: req.subtitle,
      businessType: req.businessType,
      description: req.description,
      address: req.address,
      phoneNumber: req.phoneNumber,
      phone: req.phone,
      phoneNumbers: req.phoneNumbers,
      email: req.email,
      currencyCode: req.currencyCode,
      isActive: req.isActive,
      googleMapsUrl: req.googleMapsUrl,
      latitude: req.latitude,
      longitude: req.longitude,
      websiteUrl: req.websiteUrl,
      commercialRegistration: req.commercialRegistration,
      taxNumber: req.taxNumber,
      warrantyPolicy: req.warrantyPolicy,
      returnPolicy: req.returnPolicy,
    );
  }
}

typedef RestaurantResponse = StoreResponseDto;
typedef RestaurantResponseDto = StoreResponseDto;
typedef RestaurantUserStates = StoreUserStates;

class StoreUserStates {
  static const String guest = 'guest';
  static const String authenticatedWithoutStore = 'authenticatedWithoutStore';
  static const String authenticatedWithStore = 'authenticatedWithStore';

  // Compatibility aliases
  static const String authenticatedWithoutRestaurant = authenticatedWithoutStore;
  static const String authenticatedWithRestaurant = authenticatedWithStore;
}

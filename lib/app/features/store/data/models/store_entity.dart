import 'package:equatable/equatable.dart';
import 'store_phone_number.dart';

export 'store_phone_number.dart';

/// Represents a retail / electronics store entity in the Bokra Retail platform.
class StoreEntity extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final String slogan;
  final String subtitle;
  final String businessType; // e.g., 'إلكترونيات وأجهزة ذكية', 'هواتف وملحقاتها', 'تجزئة عامة'
  final String description;
  final String? logo;
  final String? cover;

  // Legal & Tax
  final String commercialRegistration;
  final String taxNumber;
  final double taxRate;
  final bool isTaxEnabled;
  final String currency;

  // Contact
  final String phoneNumber;
  final String mobileNumber;
  final String email;
  final String website;
  final List<StorePhoneNumberInput> phoneNumbers;

  // Address & Location
  final String country;
  final String city;
  final String district;
  final String street;
  final String buildingNumber;
  final String postalCode;
  final String shortAddress;
  final String googleMapsUrl;
  final double? latitude;
  final double? longitude;

  // Owner & Access Controls (Matching ASP.NET Core spec)
  final int? ownerUserId;
  final int? _legacyUserId;
  final String? ownerName;
  final String? currentUserRole; // 'Owner' | 'Manager' | 'Staff' | null
  final bool isActive;

  // Operations & Receipt Settings for Retail & Electronics
  final String receiptHeaderNote;
  final String receiptFooterNote;
  final String warrantyPolicy;
  final String returnPolicy;
  final double serviceChargeRate; // Kept for schema compatibility (default 0.0)
  final String openingTime;
  final String closingTime;
  final String? updatedAt;

  const StoreEntity({
    this.id = 'default_store',
    required this.nameAr,
    required this.nameEn,
    this.slogan = 'وجهتكم الأولى للإلكترونيات والأجهزة الذكية',
    this.subtitle = 'إلكترونيات، هواتف ذكية وملحقاتها',
    this.businessType = 'إلكترونيات وأجهزة ذكية',
    this.description = 'متجر تجزئة متخصص في بيع وصيانة الأجهزة الإلكترونية والهواتف الذكية ومستلزمات الحواسيب بأعلى معايير الجودة والضمان المعتمد.',
    this.logo,
    this.cover,
    this.commercialRegistration = '1010123456',
    this.taxNumber = '310123456700003',
    this.taxRate = 15.0,
    this.isTaxEnabled = true,
    this.currency = 'JOD',
    this.phoneNumber = '0790000000',
    this.mobileNumber = '+962790000000',
    this.email = 'info@bokrah-retail.com',
    this.website = 'https://bokrah.com',
    this.phoneNumbers = const [],
    this.country = 'المملكة الأردنية الهاشمية',
    this.city = 'عمان',
    this.district = 'حي الشميساني',
    this.street = 'شارع الملكة رانيا',
    this.buildingNumber = '12',
    this.postalCode = '11181',
    this.shortAddress = 'AMMN1234',
    this.googleMapsUrl = 'https://maps.google.com/?q=31.9539,35.9106',
    this.latitude = 31.9539,
    this.longitude = 35.9106,
    this.ownerUserId,
    int? userId,
    this.ownerName,
    this.currentUserRole = 'Owner',
    this.isActive = true,
    this.receiptHeaderNote = 'أهلاً بكم في متجر بكرة للإلكترونيات والتجزئة',
    this.receiptFooterNote = 'شكراً لتسوقكم معنا! سياسة الاسترجاع والاستبدال خلال 7 أيام مع الفاتورة والضمان الأصلي',
    this.warrantyPolicy = 'ضمان الوكيل سنتين على كافة الأجهزة الإلكترونية والذكية',
    this.returnPolicy = 'استبدال واسترجاع خلال 7 أيام للأجهزة بحالتها الأصلية غير المفتوحة',
    this.serviceChargeRate = 0.0,
    this.openingTime = '09:00 ص',
    this.closingTime = '11:00 م',
    this.updatedAt,
  }) : _legacyUserId = userId;

  /// User / Owner ID
  int? get userId => ownerUserId ?? _legacyUserId;

  /// Currency code alias
  String get currencyCode => currency;

  /// Role-based access getters
  bool get isOwner => (currentUserRole?.toLowerCase() ?? 'owner') == 'owner';
  bool get isManager => currentUserRole?.toLowerCase() == 'manager';
  bool get isStaff => currentUserRole?.toLowerCase() == 'staff';

  /// UI / UX Guard permissions:
  /// - If Owner: Full administrative options (store settings, member management).
  /// - If Manager: View-only store settings.
  /// - If Staff: Hide store management controls.
  bool get canManageSettings => isOwner;
  bool get isReadOnlySettings => isManager;
  bool get hasSettingsAccess => isOwner || isManager;

  /// Full address string for receipts and views
  String get fullAddress {
    final parts = [country, city, district, street, buildingNumber]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? shortAddress : parts.join(' - ');
  }

  /// Compatibility getter for legacy restaurant code
  String get cuisineType => businessType;

  /// Default demo store data for retail and electronics
  factory StoreEntity.defaultStore() {
    return const StoreEntity(
      nameAr: 'متجر بكرة للإلكترونيات والتجزئة',
      nameEn: 'Bokrah Retail & Electronics',
      slogan: 'عالم التقنية الذكية والحلول الرقمية المتكاملة',
      subtitle: 'أجهزة ذكية • حواسيب • ملحقات وضمان معتمد',
      businessType: 'إلكترونيات وأجهزة ذكية',
      description:
          'متجر تجزئة رائد يقدم أحدث الهواتف الذكية والأجهزة اللوحية والحواسيب وملحقاتها، مع ضمان الوكيل وخدمات ما بعد البيع المعتمدة.',
      commercialRegistration: '1010543210',
      taxNumber: '310987654300003',
      taxRate: 15.0,
      isTaxEnabled: true,
      currency: 'JOD',
      phoneNumber: '065000000',
      mobileNumber: '+962790000000',
      email: 'sales@bokrah-retail.com',
      website: 'https://bokrah-retail.com',
      country: 'المملكة الأردنية الهاشمية',
      city: 'عمان',
      district: 'حي الجاردنز',
      street: 'شارع وصفي التل',
      buildingNumber: '44',
      postalCode: '11194',
      shortAddress: 'AMMN5678',
      googleMapsUrl: 'https://maps.google.com/?q=31.9866,35.8887',
      latitude: 31.9866,
      longitude: 35.8887,
      ownerUserId: 1,
      ownerName: 'مدير النظام المعتمد',
      currentUserRole: 'Owner',
      isActive: true,
      receiptHeaderNote: 'مرحباً بكم في متجر بكرة للإلكترونيات - فرع عمان',
      receiptFooterNote: 'الضمان ساري مع الاحتفاظ بالفاتورة الأصلية ورقم السيريال',
      warrantyPolicy: 'ضمان الوكيل الرسمي 24 شهراً يشمل العيوب المصنعية وقطع الغيار الأصلية',
      returnPolicy: 'يحق للعميل الاستبدال أو الاسترجاع خلال 7 أيام بشرط سلامة التغليف الأصلي',
      serviceChargeRate: 0.0,
      openingTime: '09:00 ص',
      closingTime: '11:00 م',
    );
  }

  /// Default demo restaurant data for compatibility
  factory StoreEntity.defaultRestaurant() {
    return const StoreEntity(
      nameAr: 'مطعم بكرة',
      nameEn: 'Bokrah Restaurant',
      slogan: 'أشهى المأكولات والمشروبات بأرقى معايير الضيافة',
      subtitle: 'مأكولات شرقية وغربية • مشويات وعصائر طازجة',
      businessType: 'مطاعم وضيافة',
      description: 'مطعم يقدم تشكيلة مختارة من أشهى الأطباق الشرقية والغربية مع جلسات عائلية متميزة.',
      commercialRegistration: '1010998877',
      taxNumber: '310554433200003',
      taxRate: 15.0,
      isTaxEnabled: true,
      currency: 'SAR',
      phoneNumber: '0119876543',
      mobileNumber: '+966559876543',
      email: 'restaurant@bokrah.com',
      website: 'https://restaurant.bokrah.com',
      country: 'المملكة العربية السعودية',
      city: 'الرياض',
      district: 'حي الملقا',
      street: 'طريق أنس بن مالك',
      buildingNumber: '88',
      postalCode: '13524',
      shortAddress: 'MLQA9988',
      googleMapsUrl: 'https://maps.google.com/?q=24.8021,46.6112',
      latitude: 24.8021,
      longitude: 46.6112,
      ownerUserId: 1,
      ownerName: 'مدير المطعم',
      currentUserRole: 'Owner',
      isActive: true,
      receiptHeaderNote: 'أهلاً بكم في مطعم مذاق بكرة الفاخر',
      receiptFooterNote: 'نشكركم لزيارتنا ونتطلع لخدمتكم دائماً بأشهى الأطباق',
      warrantyPolicy: 'ضمان الجودة والطزاجة في جميع الوجبات والمشروبات',
      returnPolicy: 'في حال وجود أي ملاحظة على الطبق يتم استبداله فوراً بدون أي تكلفة إضافية',
      serviceChargeRate: 0.0,
      openingTime: '12:00 م',
      closingTime: '01:00 ص',
    );
  }

  StoreEntity copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? slogan,
    String? subtitle,
    String? businessType,
    String? cuisineType,
    String? description,
    String? logo,
    String? cover,
    String? commercialRegistration,
    String? taxNumber,
    double? taxRate,
    bool? isTaxEnabled,
    String? currency,
    String? currencyCode,
    String? phoneNumber,
    String? mobileNumber,
    String? email,
    String? website,
    List<StorePhoneNumberInput>? phoneNumbers,
    String? country,
    String? city,
    String? district,
    String? street,
    String? buildingNumber,
    String? postalCode,
    String? shortAddress,
    String? googleMapsUrl,
    double? latitude,
    double? longitude,
    int? ownerUserId,
    int? userId,
    String? ownerName,
    String? currentUserRole,
    bool? isActive,
    String? receiptHeaderNote,
    String? receiptFooterNote,
    String? warrantyPolicy,
    String? returnPolicy,
    double? serviceChargeRate,
    String? openingTime,
    String? closingTime,
    String? updatedAt,
  }) {
    return StoreEntity(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      slogan: slogan ?? this.slogan,
      subtitle: subtitle ?? this.subtitle,
      businessType: businessType ?? cuisineType ?? this.businessType,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      cover: cover ?? this.cover,
      commercialRegistration:
          commercialRegistration ?? this.commercialRegistration,
      taxNumber: taxNumber ?? this.taxNumber,
      taxRate: taxRate ?? this.taxRate,
      isTaxEnabled: isTaxEnabled ?? this.isTaxEnabled,
      currency: currencyCode ?? currency ?? this.currency,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      country: country ?? this.country,
      city: city ?? this.city,
      district: district ?? this.district,
      street: street ?? this.street,
      buildingNumber: buildingNumber ?? this.buildingNumber,
      postalCode: postalCode ?? this.postalCode,
      shortAddress: shortAddress ?? this.shortAddress,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ownerUserId: ownerUserId ?? userId ?? this.ownerUserId,
      userId: userId ?? ownerUserId ?? this.userId,
      ownerName: ownerName ?? this.ownerName,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      isActive: isActive ?? this.isActive,
      receiptHeaderNote: receiptHeaderNote ?? this.receiptHeaderNote,
      receiptFooterNote: receiptFooterNote ?? this.receiptFooterNote,
      warrantyPolicy: warrantyPolicy ?? this.warrantyPolicy,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      serviceChargeRate: serviceChargeRate ?? this.serviceChargeRate,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'slogan': slogan,
      'subtitle': subtitle,
      'businessType': businessType,
      'cuisineType': businessType,
      'description': description,
      'logo': logo,
      'cover': cover,
      'commercialRegistration': commercialRegistration,
      'taxNumber': taxNumber,
      'taxRate': taxRate,
      'isTaxEnabled': isTaxEnabled,
      'currency': currency,
      'currencyCode': currency,
      'phoneNumber': phoneNumber,
      'mobileNumber': mobileNumber,
      'email': email,
      'website': website,
      'phoneNumbers': phoneNumbers.map((p) => p.toJson()).toList(),
      'country': country,
      'city': city,
      'district': district,
      'street': street,
      'buildingNumber': buildingNumber,
      'postalCode': postalCode,
      'shortAddress': shortAddress,
      'googleMapsUrl': googleMapsUrl,
      'latitude': latitude,
      'longitude': longitude,
      'ownerUserId': ownerUserId ?? userId,
      'userId': ownerUserId ?? userId,
      'ownerName': ownerName,
      'currentUserRole': currentUserRole,
      'isActive': isActive,
      'receiptHeaderNote': receiptHeaderNote,
      'receiptFooterNote': receiptFooterNote,
      'warrantyPolicy': warrantyPolicy,
      'returnPolicy': returnPolicy,
      'serviceChargeRate': serviceChargeRate,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory StoreEntity.fromMap(Map<String, dynamic> map) {
    List<StorePhoneNumberInput> parsedPhones = [];
    if (map['phoneNumbers'] is List) {
      parsedPhones = (map['phoneNumbers'] as List)
          .map((e) => StorePhoneNumberInput.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final resolvedType = map['businessType'] ??
        map['cuisineType'] ??
        map['subtitle'] ??
        'إلكترونيات وأجهزة ذكية';

    final parsedOwnerId = map['ownerUserId'] is int
        ? map['ownerUserId'] as int
        : (map['userId'] is int
            ? map['userId'] as int
            : int.tryParse(map['ownerUserId']?.toString() ??
                    map['userId']?.toString() ??
                    ''));

    return StoreEntity(
      id: map['id']?.toString() ?? 'default_store',
      nameAr: map['nameAr'] ?? '',
      nameEn: map['nameEn'] ?? '',
      slogan: map['slogan'] ?? '',
      subtitle: map['subtitle'] ?? resolvedType,
      businessType: resolvedType,
      description: map['description'] ?? '',
      logo: map['logo'],
      cover: map['cover'],
      commercialRegistration: map['commercialRegistration'] ?? '',
      taxNumber: map['taxNumber'] ?? '',
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 15.0,
      isTaxEnabled: map['isTaxEnabled'] ?? true,
      currency: map['currencyCode'] ?? map['currency'] ?? 'JOD',
      phoneNumber: map['phoneNumber'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
      phoneNumbers: parsedPhones,
      country: map['country'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      street: map['street'] ?? '',
      buildingNumber: map['buildingNumber'] ?? '',
      postalCode: map['postalCode'] ?? '',
      shortAddress: map['shortAddress'] ?? '',
      googleMapsUrl: map['googleMapsUrl'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      ownerUserId: parsedOwnerId,
      userId: parsedOwnerId,
      ownerName: map['ownerName'] as String?,
      currentUserRole: map['currentUserRole'] as String? ?? 'Owner',
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
      receiptHeaderNote: map['receiptHeaderNote'] ?? '',
      receiptFooterNote: map['receiptFooterNote'] ?? '',
      warrantyPolicy: map['warrantyPolicy'] ??
          'ضمان سنتين على كافة الأجهزة الإلكترونية',
      returnPolicy: map['returnPolicy'] ??
          'استبدال واسترجاع خلال 7 أيام من تاريخ الشراء مع الفاتورة الأصلية',
      serviceChargeRate: (map['serviceChargeRate'] as num?)?.toDouble() ?? 0.0,
      openingTime: map['openingTime'] ?? '09:00 ص',
      closingTime: map['closingTime'] ?? '11:00 م',
      updatedAt: map['updatedAt'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        nameAr,
        nameEn,
        slogan,
        subtitle,
        businessType,
        description,
        logo,
        cover,
        commercialRegistration,
        taxNumber,
        taxRate,
        isTaxEnabled,
        currency,
        phoneNumber,
        mobileNumber,
        email,
        website,
        phoneNumbers,
        country,
        city,
        district,
        street,
        buildingNumber,
        postalCode,
        shortAddress,
        googleMapsUrl,
        latitude,
        longitude,
        ownerUserId,
        userId,
        ownerName,
        currentUserRole,
        isActive,
        receiptHeaderNote,
        receiptFooterNote,
        warrantyPolicy,
        returnPolicy,
        serviceChargeRate,
        openingTime,
        closingTime,
        updatedAt,
      ];
}

/// Backward compatibility alias
typedef RestaurantEntity = StoreEntity;

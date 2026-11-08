// ignore_for_file: deprecated_member_use

/// Country code representation with dialing info, validation rules, and formatting.
class CountryCodeModel {
  final String nameEn;
  final String nameAr;
  final String dialCode; // e.g. "+966"
  final String isoCode; // e.g. "SA"
  final String flagEmoji;
  final int minLength;
  final int maxLength;
  final String placeholder;

  const CountryCodeModel({
    required this.nameEn,
    required this.nameAr,
    required this.dialCode,
    required this.isoCode,
    required this.flagEmoji,
    required this.minLength,
    required this.maxLength,
    required this.placeholder,
  });

  String localizedName(String languageCode) =>
      languageCode == 'ar' ? nameAr : nameEn;

  /// Validates raw national number.
  bool isValid(String rawNumber) {
    final cleaned = rawNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.isEmpty) return false;
    // Strip leading zero if present for length check
    final trimmed = cleaned.startsWith('0') ? cleaned.substring(1) : cleaned;
    return trimmed.length >= minLength &&
        trimmed.length <= maxLength &&
        RegExp(r'^\d+$').hasMatch(trimmed);
  }

  /// Normalizes to standard E.164 international format (e.g., +966501234567).
  String normalize(String rawNumber) {
    var cleaned = rawNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    // If dialCode is already prefixed, avoid duplicate
    final cleanDial = dialCode.replaceAll('+', '');
    if (cleaned.startsWith(cleanDial)) {
      return '+$cleaned';
    }
    return '$dialCode$cleaned';
  }

  static const List<CountryCodeModel> supportedCountries = [
    CountryCodeModel(
      nameEn: 'Saudi Arabia',
      nameAr: 'المملكة العربية السعودية',
      dialCode: '+966',
      isoCode: 'SA',
      flagEmoji: '🇸🇦',
      minLength: 9,
      maxLength: 9,
      placeholder: '50 123 4567',
    ),
    CountryCodeModel(
      nameEn: 'United Arab Emirates',
      nameAr: 'الإمارات العربية المتحدة',
      dialCode: '+971',
      isoCode: 'AE',
      flagEmoji: '🇦🇪',
      minLength: 9,
      maxLength: 9,
      placeholder: '50 123 4567',
    ),
    CountryCodeModel(
      nameEn: 'Egypt',
      nameAr: 'مصر',
      dialCode: '+20',
      isoCode: 'EG',
      flagEmoji: '🇪🇬',
      minLength: 10,
      maxLength: 10,
      placeholder: '10 1234 5678',
    ),
    CountryCodeModel(
      nameEn: 'Kuwait',
      nameAr: 'الكويت',
      dialCode: '+965',
      isoCode: 'KW',
      flagEmoji: '🇰🇼',
      minLength: 8,
      maxLength: 8,
      placeholder: '9123 4567',
    ),
    CountryCodeModel(
      nameEn: 'Qatar',
      nameAr: 'قطر',
      dialCode: '+974',
      isoCode: 'QA',
      flagEmoji: '🇶🇦',
      minLength: 8,
      maxLength: 8,
      placeholder: '3312 3456',
    ),
    CountryCodeModel(
      nameEn: 'Bahrain',
      nameAr: 'البحرين',
      dialCode: '+973',
      isoCode: 'BH',
      flagEmoji: '🇧🇭',
      minLength: 8,
      maxLength: 8,
      placeholder: '3912 3456',
    ),
    CountryCodeModel(
      nameEn: 'Oman',
      nameAr: 'عُمان',
      dialCode: '+968',
      isoCode: 'OM',
      flagEmoji: '🇴🇲',
      minLength: 8,
      maxLength: 8,
      placeholder: '9123 4567',
    ),
    CountryCodeModel(
      nameEn: 'Jordan',
      nameAr: 'الأردن',
      dialCode: '+962',
      isoCode: 'JO',
      flagEmoji: '🇯🇴',
      minLength: 9,
      maxLength: 9,
      placeholder: '7 9123 4567',
    ),
    CountryCodeModel(
      nameEn: 'Yemen',
      nameAr: 'اليمن',
      dialCode: '+967',
      isoCode: 'YE',
      flagEmoji: '🇾🇪',
      minLength: 8,
      maxLength: 9,
      placeholder: '77 123 4567',
    ),
    CountryCodeModel(
      nameEn: 'United States',
      nameAr: 'الولايات المتحدة',
      dialCode: '+1',
      isoCode: 'US',
      flagEmoji: '🇺🇸',
      minLength: 10,
      maxLength: 10,
      placeholder: '202 555 0123',
    ),
    CountryCodeModel(
      nameEn: 'United Kingdom',
      nameAr: 'المملكة المتحدة',
      dialCode: '+44',
      isoCode: 'GB',
      flagEmoji: '🇬🇧',
      minLength: 10,
      maxLength: 10,
      placeholder: '7911 123456',
    ),
    CountryCodeModel(
      nameEn: 'Germany',
      nameAr: 'ألمانيا',
      dialCode: '+49',
      isoCode: 'DE',
      flagEmoji: '🇩🇪',
      minLength: 10,
      maxLength: 11,
      placeholder: '151 12345678',
    ),
    CountryCodeModel(
      nameEn: 'France',
      nameAr: 'فرنسا',
      dialCode: '+33',
      isoCode: 'FR',
      flagEmoji: '🇫🇷',
      minLength: 9,
      maxLength: 9,
      placeholder: '6 12 34 56 78',
    ),
    CountryCodeModel(
      nameEn: 'Turkey',
      nameAr: 'تركيا',
      dialCode: '+90',
      isoCode: 'TR',
      flagEmoji: '🇹🇷',
      minLength: 10,
      maxLength: 10,
      placeholder: '532 123 4567',
    ),
  ];

  static CountryCodeModel get defaultCountry => supportedCountries.first;
}

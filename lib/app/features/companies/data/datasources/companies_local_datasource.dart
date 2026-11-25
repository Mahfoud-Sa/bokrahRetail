import 'dart:convert';
import 'package:bokrah_retail/app/features/companies/data/models/company_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class CompaniesLocalDataSource {
  Future<List<CompanyModel>> getAllCompanies();
  Future<CompanyModel?> getCompanyById(int id);
  Future<CompanyModel?> saveCompany(CompanyModel company);
  Future<bool> updateCompany(CompanyModel company);
  Future<bool> deleteCompany(int id);
}

class CompaniesLocalDataSourceImpl implements CompaniesLocalDataSource {
  static const String _companiesKey = 'companies_list';
  final SharedPreferences? _prefs;

  CompaniesLocalDataSourceImpl({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ?? await SharedPreferences.getInstance();

  @override
  Future<List<CompanyModel>> getAllCompanies() async {
    final prefs = await _instance;

    // Seed only on first use. Checking the key (not the list) keeps an
    // intentionally emptied list empty instead of resurrecting the defaults.
    if (!prefs.containsKey(_companiesKey)) {
      final initial = _getDefaultCompanies();
      final initialJson = initial.map((c) => json.encode(c.toMap())).toList();
      await prefs.setStringList(_companiesKey, initialJson);
      return initial;
    }

    final jsonList = prefs.getStringList(_companiesKey) ?? const [];

    return jsonList.map((jsonString) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return CompanyModel.fromMap(map);
    }).toList();
  }

  @override
  Future<CompanyModel?> getCompanyById(int id) async {
    final companies = await getAllCompanies();
    try {
      return companies.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CompanyModel?> saveCompany(CompanyModel company) async {
    try {
      final prefs = await _instance;
      final companies = await getAllCompanies();

      final newCompany = company.id != null
          ? company
          : CompanyModel(
              id: DateTime.now().millisecondsSinceEpoch,
              name: company.name,
              arabicName: company.arabicName,
              englishName: company.englishName,
              brands: company.brands,
              image: company.image,
              code: company.code,
              description: company.description,
              website: company.website,
              email: company.email,
              phone: company.phone,
              address: company.address,
              createdAt: company.createdAt,
            );

      companies.add(newCompany);

      final jsonList = companies.map((c) => json.encode(c.toMap())).toList();
      await prefs.setStringList(_companiesKey, jsonList);

      return newCompany;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> updateCompany(CompanyModel company) async {
    try {
      final prefs = await _instance;
      final companies = await getAllCompanies();

      final index = companies.indexWhere((c) => c.id == company.id);
      if (index != -1) {
        companies[index] = company;

        final jsonList = companies.map((c) => json.encode(c.toMap())).toList();
        await prefs.setStringList(_companiesKey, jsonList);

        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteCompany(int id) async {
    try {
      final prefs = await _instance;
      final companies = await getAllCompanies();

      companies.removeWhere((c) => c.id == id);

      final jsonList = companies.map((c) => json.encode(c.toMap())).toList();
      await prefs.setStringList(_companiesKey, jsonList);

      return true;
    } catch (_) {
      return false;
    }
  }

  List<CompanyModel> _getDefaultCompanies() {
    return [
      CompanyModel(
        id: 101,
        name: 'Apple',
        arabicName: 'أبل',
        englishName: 'Apple Inc.',
        code: 'AAPL',
        image: 'https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg',
        brands: ['iPhone', 'iPad', 'MacBook', 'Apple Watch', 'AirPods'],
        description: 'شركة تقنية أمريكية متعددة الجنسيات متخصصة في الإلكترونيات الاستهلاكية والبرمجيات.',
        website: 'https://www.apple.com',
        email: 'contact@apple.com',
        phone: '+1 800-692-7753',
        address: 'Cupertino, California, USA',
      ),
      CompanyModel(
        id: 102,
        name: 'Samsung',
        arabicName: 'سامسونج',
        englishName: 'Samsung Electronics',
        code: 'SAMS',
        image: 'https://upload.wikimedia.org/wikipedia/commons/2/24/Samsung_Logo.svg',
        brands: ['Galaxy', 'Odyssey', 'Neo QLED', 'SmartThings', 'Galaxy Watch'],
        description: 'تكتل كوري جنوبي رائد في تصنيع الإلكترونيات وشاشات العرض وأجهزة المحمول.',
        website: 'https://www.samsung.com',
        email: 'support@samsung.com',
        phone: '+82 2-2053-3000',
        address: 'Suwon, South Korea',
      ),
      CompanyModel(
        id: 103,
        name: 'Sony',
        arabicName: 'سوني',
        englishName: 'Sony Corporation',
        code: 'SONY',
        image: 'https://upload.wikimedia.org/wikipedia/commons/c/ca/Sony_logo.svg',
        brands: ['PlayStation', 'Bravia', 'Xperia', 'Alpha'],
        description: 'شركة يابانية رائدة في مجال الإلكترونيات وألعاب الفيديو والمعدات الترفيهية.',
        website: 'https://www.sony.com',
        email: 'info@sony.com',
        phone: '+81 3-6748-2111',
        address: 'Minato, Tokyo, Japan',
      ),
      CompanyModel(
        id: 104,
        name: 'Almarai',
        arabicName: 'المراعي',
        englishName: 'Almarai Company',
        code: 'ALMR',
        image: 'https://upload.wikimedia.org/wikipedia/en/thumb/d/d4/Almarai_logo.svg/330px-Almarai_logo.svg.png',
        brands: ['المراعي (Almarai)', 'لوزين (L\'usine)', 'سفن دايز (7 Days)', 'نيورالاك (Nuralac)', 'بيتي (Beyti)'],
        description: 'الشركة الرائدة في صناعة الأغذية والمشروبات ومنتجات الألبان في الشرق الأوسط.',
        website: 'https://www.almarai.com',
        email: 'info@almarai.com',
        phone: '+966 11 470 0005',
        address: 'Riyadh, Saudi Arabia',
      ),
      CompanyModel(
        id: 105,
        name: 'Unilever',
        arabicName: 'يونيليفر',
        englishName: 'Unilever',
        code: 'ULVR',
        image: 'https://upload.wikimedia.org/wikipedia/en/thumb/8/87/Unilever.svg/330px-Unilever.svg.png',
        brands: ['Dove', 'Lipton', 'Sunsilk', 'Lifebuoy', 'Knorr', 'Rexona', 'Axe'],
        description: 'إحدى كبرى الشركات العالمية في إنتاج السلع الاستهلاكية ومستحضرات العناية الشخصية والمنزلية.',
        website: 'https://www.unilever.com',
        email: 'contact@unilever.com',
        phone: '+44 20 7822 5252',
        address: 'London, United Kingdom',
      ),
    ];
  }
}

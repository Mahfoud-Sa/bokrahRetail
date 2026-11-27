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
}

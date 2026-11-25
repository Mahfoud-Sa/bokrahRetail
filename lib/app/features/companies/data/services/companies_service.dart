import 'package:bokrah_retail/app/features/companies/data/repositories/companies_repository_impl.dart';
import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/companies/domain/repositories/companies_repository.dart';

class CompaniesService {
  final CompaniesRepository _repository;

  CompaniesService({CompaniesRepository? repository})
      : _repository = repository ?? CompaniesRepositoryImpl();

  Future<List<CompanyEntity>> getAllCompanies() =>
      _repository.getAllCompanies();

  Future<CompanyEntity?> getCompanyById(int id) =>
      _repository.getCompanyById(id);

  /// Validates and saves a new company record
  Future<CompanyEntity?> saveCompany(CompanyEntity company) {
    if (company.arabicName.trim().isEmpty && company.englishName.trim().isEmpty) {
      throw ArgumentError('Company must have at least an Arabic or English name');
    }
    return _repository.saveCompany(company);
  }

  /// Validates and updates an existing company record
  Future<bool> updateCompany(CompanyEntity company) {
    if (company.id == null) {
      throw ArgumentError('Cannot update company without an ID');
    }
    return _repository.updateCompany(company);
  }

  Future<bool> deleteCompany(int id) => _repository.deleteCompany(id);

  Future<List<String>> getAllBrands() => _repository.getAllBrands();

  /// Search companies using the domain entity's encapsulated matching rule
  List<CompanyEntity> searchCompanies(List<CompanyEntity> list, String query) {
    if (query.trim().isEmpty) return list;
    return list.where((c) => c.matches(query)).toList();
  }

  /// Locates a company by any of its name variants (Arabic, English, or commercial)
  CompanyEntity? findMatchingCompany(List<CompanyEntity> list, String nameOrQuery) {
    try {
      return list.firstWhere((c) => c.matchesName(nameOrQuery));
    } catch (_) {
      return null;
    }
  }

  /// Collects all brands that belong to a matching company name
  List<String> getBrandsForCompany(List<CompanyEntity> list, String companyName) {
    final company = findMatchingCompany(list, companyName);
    return company?.brands ?? const [];
  }
}

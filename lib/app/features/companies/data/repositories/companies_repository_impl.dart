import 'package:bokrah_retail/app/features/companies/data/datasources/companies_local_datasource.dart';
import 'package:bokrah_retail/app/features/companies/data/models/company_model.dart';
import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/companies/domain/repositories/companies_repository.dart';

class CompaniesRepositoryImpl implements CompaniesRepository {
  final CompaniesLocalDataSource _localDataSource;

  CompaniesRepositoryImpl({CompaniesLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? CompaniesLocalDataSourceImpl();

  @override
  Future<List<CompanyEntity>> getAllCompanies() =>
      _localDataSource.getAllCompanies();

  @override
  Future<CompanyEntity?> getCompanyById(int id) =>
      _localDataSource.getCompanyById(id);

  @override
  Future<CompanyEntity?> saveCompany(CompanyEntity company) {
    final model = company is CompanyModel
        ? company
        : CompanyModel.fromEntity(company);
    return _localDataSource.saveCompany(model);
  }

  @override
  Future<bool> updateCompany(CompanyEntity company) {
    final model = company is CompanyModel
        ? company
        : CompanyModel.fromEntity(company);
    return _localDataSource.updateCompany(model);
  }

  @override
  Future<bool> deleteCompany(int id) => _localDataSource.deleteCompany(id);

  @override
  Future<List<String>> getAllBrands() async {
    final companies = await _localDataSource.getAllCompanies();
    final brands = <String>{};
    for (final c in companies) {
      brands.addAll(c.brands);
    }
    return brands.toList()..sort();
  }
}

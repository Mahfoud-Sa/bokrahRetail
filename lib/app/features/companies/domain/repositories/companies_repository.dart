import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';

abstract class CompaniesRepository {
  Future<List<CompanyEntity>> getAllCompanies();
  Future<CompanyEntity?> getCompanyById(int id);
  Future<CompanyEntity?> saveCompany(CompanyEntity company);
  Future<bool> updateCompany(CompanyEntity company);
  Future<bool> deleteCompany(int id);
  Future<List<String>> getAllBrands();
}

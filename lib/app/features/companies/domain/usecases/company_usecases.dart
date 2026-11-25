import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/companies/domain/repositories/companies_repository.dart';

class GetAllCompaniesUseCase {
  final CompaniesRepository repository;
  GetAllCompaniesUseCase(this.repository);

  Future<List<CompanyEntity>> call() => repository.getAllCompanies();
}

class GetCompanyByIdUseCase {
  final CompaniesRepository repository;
  GetCompanyByIdUseCase(this.repository);

  Future<CompanyEntity?> call(int id) => repository.getCompanyById(id);
}

class SaveCompanyUseCase {
  final CompaniesRepository repository;
  SaveCompanyUseCase(this.repository);

  Future<CompanyEntity?> call(CompanyEntity company) {
    if (company.arabicName.trim().isEmpty && company.englishName.trim().isEmpty) {
      throw ArgumentError('Company must have at least an Arabic or English name');
    }
    return repository.saveCompany(company);
  }
}

class UpdateCompanyUseCase {
  final CompaniesRepository repository;
  UpdateCompanyUseCase(this.repository);

  Future<bool> call(CompanyEntity company) {
    if (company.id == null) {
      throw ArgumentError('Cannot update company without an ID');
    }
    return repository.updateCompany(company);
  }
}

class DeleteCompanyUseCase {
  final CompaniesRepository repository;
  DeleteCompanyUseCase(this.repository);

  Future<bool> call(int id) => repository.deleteCompany(id);
}

class GetAllBrandsUseCase {
  final CompaniesRepository repository;
  GetAllBrandsUseCase(this.repository);

  Future<List<String>> call() => repository.getAllBrands();
}

class SearchCompaniesUseCase {
  SearchCompaniesUseCase();

  List<CompanyEntity> call(List<CompanyEntity> companies, String query) {
    if (query.trim().isEmpty) return companies;
    return companies.where((c) => c.matches(query)).toList();
  }
}

import 'package:bokrah_retail/app/features/companies/data/datasources/companies_local_datasource.dart';
import 'package:bokrah_retail/app/features/companies/data/models/company_model.dart';
import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/companies/domain/repositories/companies_repository.dart';
import 'package:bokrah_retail/app/features/sync/data/services/sync_outbox_recorder.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';

class CompaniesRepositoryImpl implements CompaniesRepository {
  final CompaniesLocalDataSource _localDataSource;
  final SyncOutboxRecorder _outboxRecorder;

  CompaniesRepositoryImpl({
    CompaniesLocalDataSource? localDataSource,
    SyncOutboxRecorder? outboxRecorder,
  })  : _localDataSource = localDataSource ?? CompaniesLocalDataSourceImpl(),
        _outboxRecorder = outboxRecorder ?? SyncOutboxRecorder();

  @override
  Future<List<CompanyEntity>> getAllCompanies() =>
      _localDataSource.getAllCompanies();

  @override
  Future<CompanyEntity?> getCompanyById(int id) =>
      _localDataSource.getCompanyById(id);

  @override
  Future<CompanyEntity?> saveCompany(CompanyEntity company) async {
    final model = company is CompanyModel
        ? company
        : CompanyModel.fromEntity(company);
    final saved = await _localDataSource.saveCompany(model);
    if (saved != null && saved.id != null) {
      await _outboxRecorder.record(
        entityType: SyncEntityType.company,
        operationType: SyncOperationType.create,
        localEntityId: saved.id!,
        payload: CompanyModel.fromEntity(saved).toMap(),
      );
    }
    return saved;
  }

  @override
  Future<bool> updateCompany(CompanyEntity company) async {
    final model = company is CompanyModel
        ? company
        : CompanyModel.fromEntity(company);
    final ok = await _localDataSource.updateCompany(model);
    if (ok && company.id != null) {
      await _outboxRecorder.record(
        entityType: SyncEntityType.company,
        operationType: SyncOperationType.update,
        localEntityId: company.id!,
        payload: model.toMap(),
      );
    }
    return ok;
  }

  @override
  Future<bool> deleteCompany(int id) async {
    final ok = await _localDataSource.deleteCompany(id);
    if (ok) {
      await _outboxRecorder.record(
        entityType: SyncEntityType.company,
        operationType: SyncOperationType.delete,
        localEntityId: id,
      );
    }
    return ok;
  }

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

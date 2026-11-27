import 'dart:convert';
import 'dart:typed_data';

import 'package:bokrah_retail/app/core/database/app_database.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/models/auth_session_model.dart';
import 'package:bokrah_retail/app/features/companies/data/datasources/companies_drift_datasource.dart';
import 'package:bokrah_retail/app/features/companies/data/models/company_model.dart';
import 'package:bokrah_retail/app/features/companies/data/repositories/companies_repository_impl.dart';
import 'package:bokrah_retail/app/features/store/data/services/store_service.dart';
import 'package:bokrah_retail/app/features/sync/data/datasources/catalog_sync_remote_datasource.dart';
import 'package:bokrah_retail/app/features/sync/data/datasources/sync_outbox_local_datasource.dart';
import 'package:bokrah_retail/app/features/sync/data/services/catalog_local_cache_store.dart';
import 'package:bokrah_retail/app/features/sync/data/services/sync_engine.dart';
import 'package:bokrah_retail/app/features/sync/data/services/sync_outbox_recorder.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late CompaniesDriftDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    dataSource = CompaniesDriftDataSource(database: db, prefs: prefs);
  });

  tearDown(() async {
    await db.close();
  });

  test('starts empty when no companies exist and remains empty after deletion', () async {
    expect(await dataSource.getAllCompanies(), isEmpty);

    final saved = await dataSource.saveCompany(
      CompanyModel(
        name: 'Temp Co',
        arabicName: 'شركة مؤقتة',
        englishName: 'Temp Co',
        brands: const ['B1'],
      ),
    );
    expect(saved, isNotNull);

    await dataSource.deleteCompany(saved!.id!);
    expect(await dataSource.getAllCompanies(), isEmpty);
  });

  test('migrates existing SharedPreferences companies into Drift on first run', () async {
    final legacyCompany = CompanyModel(
      id: 777,
      name: 'Legacy Co',
      arabicName: 'شركة قديمة',
      englishName: 'Legacy Co',
      brands: const ['BrandA'],
    );
    await prefs.setStringList(
      'companies_list',
      [json.encode(legacyCompany.toMap())],
    );

    final loaded = await dataSource.getAllCompanies();
    expect(loaded.length, 1);
    expect(loaded.first.id, 777);
    expect(loaded.first.arabicName, 'شركة قديمة');
    expect(loaded.first.brands, ['BrandA']);
  });

  test('supports CRUD operations in Drift SQLite', () async {
    await dataSource.getAllCompanies(); // trigger seed

    final saved = await dataSource.saveCompany(
      CompanyModel(
        name: 'Almarai Test',
        arabicName: 'شركة اختبار',
        englishName: 'Test Co',
        brands: const ['B1', 'B2'],
        code: 'TST',
      ),
    );
    expect(saved, isNotNull);
    expect(saved!.id, isNotNull);

    final fetched = await dataSource.getCompanyById(saved.id!);
    expect(fetched?.englishName, 'Test Co');
    expect(fetched?.brands, ['B1', 'B2']);

    final updated = await dataSource.updateCompany(
      CompanyModel.fromEntity(
        fetched!.copyWith(arabicName: 'شركة محدثة', brands: const ['B1', 'B3']),
      ),
    );
    expect(updated, isTrue);

    final afterUpdate = await dataSource.getCompanyById(saved.id!);
    expect(afterUpdate?.arabicName, 'شركة محدثة');
    expect(afterUpdate?.brands, ['B1', 'B3']);

    final deleted = await dataSource.deleteCompany(saved.id!);
    expect(deleted, isTrue);
    expect(await dataSource.getCompanyById(saved.id!), isNull);
  });

  test('saves locally in Drift and syncs to cloud via SyncEngine', () async {
    final authStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
    await authStorage.saveSession(
      AuthSessionModel(
        accessToken: 'token-1',
        refreshToken: 'refresh-1',
        phoneNumber: '+966500000000',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        userId: 'u1',
        name: 'Admin',
      ),
    );
    final storeService = StoreService();
    await storeService.setActiveStoreId(1);

    final outbox = SyncOutboxLocalDataSource(prefs: prefs);
    final remote = MockCatalogSyncRemoteDataSource(prefs: prefs);
    final cacheStore = CatalogLocalCacheStore(
      prefs: prefs,
      companiesDriftDataSource: dataSource,
    );
    final engine = SyncEngine(
      outbox: outbox,
      remote: remote,
      cacheStore: cacheStore,
    );

    final repo = CompaniesRepositoryImpl(
      localDataSource: dataSource,
      outboxRecorder: SyncOutboxRecorder(
        syncRepository: engine,
        tokenStorage: authStorage,
        storeService: storeService,
      ),
    );

    final sampleBytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
    final created = await repo.saveCompany(
      CompanyModel(
        name: 'Cloud Co',
        arabicName: 'شركة سحابية',
        englishName: 'Cloud Co',
        brands: const ['CloudBrand'],
        imageBytes: sampleBytes,
      ),
    );
    expect(created, isNotNull);
    expect(created!.imageBytes, sampleBytes);

    // Queued locally in outbox before sync (base64 payload included)
    final pendingOps = await engine.getPendingOperations(1);
    expect(pendingOps.length, 1);
    expect(pendingOps.first.payload['imageBytesBase64'], isNotNull);

    // Sync pushes to mock remote and updates Drift
    final summary = await engine.syncStore(1);
    expect(summary.pushedCount, 1);
    expect(summary.pendingCount, 0);

    final snapshot = await remote.pullAll(1);
    final remoteCompanies = snapshot.records.values.expand((e) => e).toList();
    expect(remoteCompanies.any((m) => m['englishName'] == 'Cloud Co'), isTrue);
  });
}

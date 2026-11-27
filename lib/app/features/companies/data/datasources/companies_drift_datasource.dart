import 'dart:convert';

import 'package:bokrah_retail/app/core/database/app_database.dart';
import 'package:bokrah_retail/app/features/companies/data/datasources/companies_local_datasource.dart';
import 'package:bokrah_retail/app/features/companies/data/models/company_model.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drift/SQLite-backed implementation of [CompaniesLocalDataSource].
///
/// Stores companies locally in SQLite and supports one-time migration from
/// legacy `SharedPreferences` (`companies_list`) as well as cloud sync updates.
class CompaniesDriftDataSource implements CompaniesLocalDataSource {
  static const String _legacyPrefsKey = 'companies_list';

  final AppDatabase _db;
  final SharedPreferences? _prefs;
  bool _initialized = false;

  CompaniesDriftDataSource({
    required AppDatabase database,
    SharedPreferences? prefs,
  })  : _db = database,
        _prefs = prefs;

  Future<void> _ensureSeededOrMigrated() async {
    if (_initialized) return;
    _initialized = true;

    final existing = await _db.select(_db.companies).get();
    if (existing.isNotEmpty) return;

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (prefs.containsKey(_legacyPrefsKey)) {
      final legacyJson = prefs.getStringList(_legacyPrefsKey) ?? const [];
      if (legacyJson.isNotEmpty) {
        await _db.batch((batch) {
          for (final raw in legacyJson) {
            final map = json.decode(raw) as Map<String, dynamic>;
            final model = CompanyModel.fromMap(map);
            batch.insert(
              _db.companies,
              _toCompanion(model, includeId: model.id != null),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
      }
      await prefs.remove(_legacyPrefsKey);
    }
  }

  @override
  Future<List<CompanyModel>> getAllCompanies() async {
    await _ensureSeededOrMigrated();
    final rows = await _db.select(_db.companies).get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<CompanyModel?> getCompanyById(int id) async {
    await _ensureSeededOrMigrated();
    final row = await (_db.select(_db.companies)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<CompanyModel?> saveCompany(CompanyModel company) async {
    try {
      await _ensureSeededOrMigrated();
      final insertedId = await _db.into(_db.companies).insert(
            _toCompanion(company, includeId: company.id != null),
            mode: InsertMode.insertOrReplace,
          );
      return getCompanyById(company.id ?? insertedId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> updateCompany(CompanyModel company) async {
    if (company.id == null) return false;
    try {
      await _ensureSeededOrMigrated();
      final updatedCount = await (_db.update(_db.companies)
            ..where((t) => t.id.equals(company.id!)))
          .write(_toCompanion(company, includeId: false));
      return updatedCount > 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteCompany(int id) async {
    try {
      await _ensureSeededOrMigrated();
      final deletedCount = await (_db.delete(_db.companies)
            ..where((t) => t.id.equals(id)))
          .go();
      return deletedCount > 0;
    } catch (_) {
      return false;
    }
  }

  /// Upserts a canonical server-synced company record, replacing [localId]
  /// when the backend assigns a new ID.
  Future<void> upsertSyncedCompany({
    required int localId,
    required CompanyModel canonical,
  }) async {
    await _db.transaction(() async {
      if (canonical.id != null && canonical.id != localId) {
        await (_db.delete(_db.companies)..where((t) => t.id.equals(localId)))
            .go();
      }
      await _db.into(_db.companies).insert(
            _toCompanion(canonical, includeId: canonical.id != null, isSynced: true),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  /// Merges pulled server records into Drift while preserving any companies
  /// with pending local outbox edits ([protectedLocalIds]).
  Future<int> mergePulledCompanies({
    required List<CompanyModel> pulled,
    required Set<int> protectedLocalIds,
  }) async {
    if (pulled.isEmpty) return 0;
    await _ensureSeededOrMigrated();

    await _db.transaction(() async {
      final existing = await _db.select(_db.companies).get();
      for (final row in existing) {
        if (!protectedLocalIds.contains(row.id)) {
          await (_db.delete(_db.companies)..where((t) => t.id.equals(row.id)))
              .go();
        }
      }
      for (final company in pulled) {
        if (company.id != null && protectedLocalIds.contains(company.id)) {
          continue;
        }
        await _db.into(_db.companies).insert(
              _toCompanion(
                company,
                includeId: company.id != null,
                isSynced: true,
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });

    return pulled.length;
  }

  CompanyModel _fromRow(CompanyRow row) {
    final brands = (json.decode(row.brandsJson) as List<dynamic>)
        .map((e) => e.toString())
        .toList();
    return CompanyModel(
      id: row.id,
      name: row.name,
      arabicName: row.arabicName,
      englishName: row.englishName,
      brands: brands,
      image: row.image,
      imageBytes: row.imageBytes,
      code: row.code,
      description: row.description,
      website: row.website,
      email: row.email,
      phone: row.phone,
      address: row.address,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  CompaniesCompanion _toCompanion(
    CompanyModel company, {
    required bool includeId,
    bool isSynced = false,
  }) {
    return CompaniesCompanion(
      id: includeId && company.id != null
          ? Value(company.id!)
          : const Value.absent(),
      name: Value(company.name),
      arabicName: Value(company.arabicName),
      englishName: Value(company.englishName),
      brandsJson: Value(json.encode(company.brands)),
      image: Value(company.image),
      imageBytes: Value(company.imageBytes),
      code: Value(company.code),
      description: Value(company.description),
      website: Value(company.website),
      email: Value(company.email),
      phone: Value(company.phone),
      address: Value(company.address),
      createdAt: Value(company.createdAt),
      updatedAt: Value(company.updatedAt),
      isSynced: Value(isSynced),
    );
  }
}

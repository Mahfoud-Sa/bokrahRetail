import 'dart:convert';

import 'package:bokrah_retail/app/features/companies/data/datasources/companies_drift_datasource.dart';
import 'package:bokrah_retail/app/features/companies/data/models/company_model.dart';
import 'package:bokrah_retail/app/features/departments/data/datasources/departments_drift_datasource.dart';
import 'package:bokrah_retail/app/features/departments/data/models/department_model.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads and updates the local caches for all 6 catalog resource types during
/// synchronization (routing Companies and Departments through their Drift
/// data sources when configured, and other resources through [SharedPreferences]).
class CatalogLocalCacheStore {
  final SharedPreferences? _prefs;
  final CompaniesDriftDataSource? _companiesDriftDataSource;
  final DepartmentsDriftDataSource? _departmentsDriftDataSource;

  CatalogLocalCacheStore({
    SharedPreferences? prefs,
    CompaniesDriftDataSource? companiesDriftDataSource,
    DepartmentsDriftDataSource? departmentsDriftDataSource,
  })  : _prefs = prefs,
        _companiesDriftDataSource = companiesDriftDataSource,
        _departmentsDriftDataSource = departmentsDriftDataSource;

  Future<SharedPreferences> get _instance async =>
      _prefs ?? await SharedPreferences.getInstance();

  static String storageKeyFor(SyncEntityType type) {
    switch (type) {
      case SyncEntityType.company:
        return 'companies_list';
      case SyncEntityType.department:
        return 'departments_list';
      case SyncEntityType.category:
        return 'categories_list';
      case SyncEntityType.unit:
        return 'units_list';
      case SyncEntityType.item:
        return 'items_list';
      case SyncEntityType.barcode:
        return 'barcodes_list';
      case SyncEntityType.barcodeLink:
        return 'barcode_item_links';
    }
  }

  Future<List<Map<String, dynamic>>> readRecords(SyncEntityType type) async {
    final prefs = await _instance;
    final raw = prefs.getStringList(storageKeyFor(type)) ?? const [];
    return raw
        .map((s) => Map<String, dynamic>.from(json.decode(s) as Map))
        .toList();
  }

  Future<void> writeRecords(
    SyncEntityType type,
    List<Map<String, dynamic>> records,
  ) async {
    final prefs = await _instance;
    await prefs.setStringList(
      storageKeyFor(type),
      records.map((m) => json.encode(m)).toList(),
    );
  }

  /// Upserts a canonical server record into the local cache, replacing any
  /// temporary [localId] entry if the server assigned a new [serverId].
  Future<void> upsertCanonicalRecord({
    required SyncEntityType type,
    required int localId,
    required Map<String, dynamic> canonical,
  }) async {
    if (type == SyncEntityType.company && _companiesDriftDataSource != null) {
      await _companiesDriftDataSource.upsertSyncedCompany(
        localId: localId,
        canonical: CompanyModel.fromMap(canonical),
      );
      return;
    }

    if (type == SyncEntityType.department &&
        _departmentsDriftDataSource != null) {
      await _departmentsDriftDataSource.upsertSyncedDepartment(
        localId: localId,
        canonical: DepartmentModel.fromMap(canonical),
      );
      return;
    }

    final records = await readRecords(type);
    final serverId = (canonical['id'] as num?)?.toInt() ?? localId;

    if (type == SyncEntityType.barcodeLink) {
      records.removeWhere(
        (m) =>
            m['itemId'] == canonical['itemId'] &&
            m['barcodeId'] == canonical['barcodeId'],
      );
      records.add(canonical);
      await writeRecords(type, records);
      return;
    }

    records.removeWhere((m) {
      final id = (m['id'] as num?)?.toInt();
      return id == localId || id == serverId;
    });
    records.add(canonical);
    await writeRecords(type, records);
  }

  /// Removes a record from the local cache (e.g. when server wins on a deleted
  /// or conflict-resolved record).
  Future<void> removeRecord({
    required SyncEntityType type,
    required int entityId,
    Map<String, dynamic>? matchPayload,
  }) async {
    if (type == SyncEntityType.department &&
        _departmentsDriftDataSource != null) {
      await _departmentsDriftDataSource.deleteDepartment(entityId);
      return;
    }

    final records = await readRecords(type);
    if (type == SyncEntityType.barcodeLink && matchPayload != null) {
      records.removeWhere(
        (m) =>
            m['itemId'] == matchPayload['itemId'] &&
            m['barcodeId'] == matchPayload['barcodeId'],
      );
    } else {
      records.removeWhere((m) => (m['id'] as num?)?.toInt() == entityId);
    }
    await writeRecords(type, records);
  }

  /// Merges pulled server records into the local cache while preserving any
  /// records that still have pending local outbox mutations.
  Future<int> mergePulledRecords({
    required SyncEntityType type,
    required List<Map<String, dynamic>> pulled,
    required Set<int> protectedLocalIds,
  }) async {
    if (pulled.isEmpty) return 0;

    if (type == SyncEntityType.company && _companiesDriftDataSource != null) {
      return _companiesDriftDataSource.mergePulledCompanies(
        pulled: pulled.map(CompanyModel.fromMap).toList(),
        protectedLocalIds: protectedLocalIds,
      );
    }

    if (type == SyncEntityType.department &&
        _departmentsDriftDataSource != null) {
      return _departmentsDriftDataSource.mergePulledDepartments(
        pulled: pulled.map(DepartmentModel.fromMap).toList(),
        protectedLocalIds: protectedLocalIds,
      );
    }

    final current = await readRecords(type);
    if (type == SyncEntityType.barcodeLink) {
      final merged = <Map<String, dynamic>>[...pulled];
      for (final local in current) {
        final itemId = (local['itemId'] as num?)?.toInt();
        if (itemId != null && protectedLocalIds.contains(itemId)) {
          final exists = merged.any(
            (m) =>
                m['itemId'] == local['itemId'] &&
                m['barcodeId'] == local['barcodeId'],
          );
          if (!exists) merged.add(local);
        }
      }
      await writeRecords(type, merged);
      return pulled.length;
    }

    final mergedById = <int, Map<String, dynamic>>{};
    for (final serverRecord in pulled) {
      final id = (serverRecord['id'] as num?)?.toInt();
      if (id != null) {
        mergedById[id] = serverRecord;
      }
    }

    for (final localRecord in current) {
      final id = (localRecord['id'] as num?)?.toInt();
      if (id != null && protectedLocalIds.contains(id)) {
        mergedById[id] = localRecord;
      }
    }

    await writeRecords(type, mergedById.values.toList());
    return pulled.length;
  }
}

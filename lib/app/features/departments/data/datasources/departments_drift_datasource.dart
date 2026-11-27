import 'dart:convert';

import 'package:bokrah_retail/app/core/database/app_database.dart';
import 'package:bokrah_retail/app/features/departments/data/datasources/departments_local_datasource.dart';
import 'package:bokrah_retail/app/features/departments/data/models/department_model.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drift/SQLite-backed implementation of [DepartmentsLocalDataSource].
///
/// Stores departments locally in SQLite and supports one-time migration from
/// legacy `SharedPreferences` (`departments_list`) as well as cloud sync updates.
class DepartmentsDriftDataSource implements DepartmentsLocalDataSource {
  static const String _legacyPrefsKey = 'departments_list';

  final AppDatabase _db;
  final SharedPreferences? _prefs;
  bool _initialized = false;

  DepartmentsDriftDataSource({
    required AppDatabase database,
    SharedPreferences? prefs,
  })  : _db = database,
        _prefs = prefs;

  Future<void> _ensureSeededOrMigrated() async {
    if (_initialized) return;
    _initialized = true;

    final existing = await _db.select(_db.departments).get();
    if (existing.isNotEmpty) return;

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (prefs.containsKey(_legacyPrefsKey)) {
      final legacyJson = prefs.getStringList(_legacyPrefsKey) ?? const [];
      if (legacyJson.isNotEmpty) {
        await _db.batch((batch) {
          for (final raw in legacyJson) {
            final map = json.decode(raw) as Map<String, dynamic>;
            final model = DepartmentModel.fromMap(map);
            batch.insert(
              _db.departments,
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
  Future<List<DepartmentModel>> getAllDepartments() async {
    await _ensureSeededOrMigrated();
    final rows = await _db.select(_db.departments).get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<DepartmentModel?> getDepartmentById(int id) async {
    await _ensureSeededOrMigrated();
    final row = await (_db.select(_db.departments)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<DepartmentModel?> saveDepartment(DepartmentModel department) async {
    try {
      await _ensureSeededOrMigrated();
      final insertedId = await _db.into(_db.departments).insert(
            _toCompanion(department, includeId: department.id != null),
            mode: InsertMode.insertOrReplace,
          );
      return getDepartmentById(department.id ?? insertedId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> updateDepartment(DepartmentModel department) async {
    if (department.id == null) return false;
    try {
      await _ensureSeededOrMigrated();
      final updatedCount = await (_db.update(_db.departments)
            ..where((t) => t.id.equals(department.id!)))
          .write(_toCompanion(department, includeId: false));
      return updatedCount > 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteDepartment(int id) async {
    try {
      await _ensureSeededOrMigrated();
      final deletedCount = await (_db.delete(_db.departments)
            ..where((t) => t.id.equals(id)))
          .go();
      return deletedCount > 0;
    } catch (_) {
      return false;
    }
  }

  /// Upserts a canonical server-synced department record, replacing [localId]
  /// when the backend assigns a new ID.
  Future<void> upsertSyncedDepartment({
    required int localId,
    required DepartmentModel canonical,
  }) async {
    await _db.transaction(() async {
      if (canonical.id != null && canonical.id != localId) {
        await (_db.delete(_db.departments)..where((t) => t.id.equals(localId)))
            .go();
      }
      await _db.into(_db.departments).insert(
            _toCompanion(
              canonical,
              includeId: canonical.id != null,
              isSynced: true,
            ),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  /// Merges pulled server records into Drift while preserving any departments
  /// with pending local outbox edits ([protectedLocalIds]).
  Future<int> mergePulledDepartments({
    required List<DepartmentModel> pulled,
    required Set<int> protectedLocalIds,
  }) async {
    if (pulled.isEmpty) return 0;
    await _ensureSeededOrMigrated();

    await _db.transaction(() async {
      final existing = await _db.select(_db.departments).get();
      for (final row in existing) {
        if (!protectedLocalIds.contains(row.id)) {
          await (_db.delete(_db.departments)
                ..where((t) => t.id.equals(row.id)))
              .go();
        }
      }
      for (final department in pulled) {
        if (department.id != null && protectedLocalIds.contains(department.id)) {
          continue;
        }
        await _db.into(_db.departments).insert(
              _toCompanion(
                department,
                includeId: department.id != null,
                isSynced: true,
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });

    return pulled.length;
  }

  DepartmentModel _fromRow(DepartmentRow row) {
    return DepartmentModel(
      id: row.id,
      name: row.name,
      code: row.code,
      description: row.description,
      createdAt: row.createdAt,
    );
  }

  DepartmentsCompanion _toCompanion(
    DepartmentModel department, {
    required bool includeId,
    bool isSynced = false,
  }) {
    return DepartmentsCompanion(
      id: includeId && department.id != null
          ? Value(department.id!)
          : const Value.absent(),
      name: Value(department.name),
      code: Value(department.code),
      description: Value(department.description),
      createdAt: Value(department.createdAt),
      updatedAt: Value(DateTime.now()),
      isSynced: Value(isSynced),
    );
  }
}

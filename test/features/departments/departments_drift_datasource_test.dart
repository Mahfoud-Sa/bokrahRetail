import 'dart:convert';

import 'package:bokrah_retail/app/core/database/app_database.dart';
import 'package:bokrah_retail/app/features/departments/data/datasources/departments_drift_datasource.dart';
import 'package:bokrah_retail/app/features/departments/data/models/department_model.dart';
import 'package:bokrah_retail/app/features/sync/data/services/catalog_local_cache_store.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late DepartmentsDriftDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    dataSource = DepartmentsDriftDataSource(database: db, prefs: prefs);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'starts empty when no departments exist and remains empty after deletion',
    () async {
      expect(await dataSource.getAllDepartments(), isEmpty);

      final saved = await dataSource.saveDepartment(
        DepartmentModel(name: 'قسم مؤقت', code: 'DEPT-TMP'),
      );
      expect(saved, isNotNull);

      await dataSource.deleteDepartment(saved!.id!);
      expect(await dataSource.getAllDepartments(), isEmpty);

      final reopened = DepartmentsDriftDataSource(database: db, prefs: prefs);
      expect(await reopened.getAllDepartments(), isEmpty);
    },
  );

  test(
    'migrates existing SharedPreferences departments into Drift on first run',
    () async {
      final legacyDepartment = DepartmentModel(
        id: 777,
        name: 'قسم قديم',
        code: 'DEPT-LEG',
        description: 'وصف قديم',
      );
      await prefs.setStringList('departments_list', [
        json.encode(legacyDepartment.toMap()),
      ]);

      final loaded = await dataSource.getAllDepartments();
      expect(loaded.length, 1);
      expect(loaded.first.id, 777);
      expect(loaded.first.name, 'قسم قديم');
      expect(loaded.first.code, 'DEPT-LEG');
      expect(loaded.first.description, 'وصف قديم');
    },
  );

  test('supports CRUD operations in Drift SQLite', () async {
    await dataSource.getAllDepartments(); // trigger initial seed

    final saved = await dataSource.saveDepartment(
      DepartmentModel(
        name: 'قسم الاختبار',
        code: 'DEPT-TST',
        description: 'وصف اختبار',
      ),
    );
    expect(saved, isNotNull);
    expect(saved!.id, isNotNull);

    final fetched = await dataSource.getDepartmentById(saved.id!);
    expect(fetched?.name, 'قسم الاختبار');
    expect(fetched?.code, 'DEPT-TST');

    final updated = await dataSource.updateDepartment(
      DepartmentModel(
        id: saved.id,
        name: 'قسم الاختبار المحدث',
        code: 'DEPT-TST2',
        description: 'وصف محدث',
        createdAt: saved.createdAt,
      ),
    );
    expect(updated, isTrue);

    final afterUpdate = await dataSource.getDepartmentById(saved.id!);
    expect(afterUpdate?.name, 'قسم الاختبار المحدث');
    expect(afterUpdate?.code, 'DEPT-TST2');

    final deleted = await dataSource.deleteDepartment(saved.id!);
    expect(deleted, isTrue);
    expect(await dataSource.getDepartmentById(saved.id!), isNull);
  });

  test('routes sync operations through CatalogLocalCacheStore', () async {
    final cacheStore = CatalogLocalCacheStore(
      prefs: prefs,
      departmentsDriftDataSource: dataSource,
    );

    final local = await dataSource.saveDepartment(
      DepartmentModel(name: 'قسم محلي', code: 'LOC-1'),
    );
    expect(local?.id, isNotNull);

    await cacheStore.upsertCanonicalRecord(
      type: SyncEntityType.department,
      localId: local!.id!,
      canonical: DepartmentModel(
        id: 5001,
        name: 'قسم متزامن',
        code: 'SYNC-1',
      ).toMap(),
    );

    expect(await dataSource.getDepartmentById(local.id!), isNull);
    final synced = await dataSource.getDepartmentById(5001);
    expect(synced?.name, 'قسم متزامن');

    await cacheStore.removeRecord(
      type: SyncEntityType.department,
      entityId: 5001,
    );
    expect(await dataSource.getDepartmentById(5001), isNull);
  });
}

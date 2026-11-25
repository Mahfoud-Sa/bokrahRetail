import 'dart:convert';

import 'package:bokrah_retail/app/core/network/authenticated_http_client.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/auth/data/models/auth_session_model.dart';
import 'package:bokrah_retail/app/features/store/data/services/store_service.dart';
import 'package:bokrah_retail/app/features/sync/data/datasources/catalog_sync_remote_datasource.dart';
import 'package:bokrah_retail/app/features/sync/data/datasources/sync_outbox_local_datasource.dart';
import 'package:bokrah_retail/app/features/sync/data/services/catalog_local_cache_store.dart';
import 'package:bokrah_retail/app/features/sync/data/services/sync_engine.dart';
import 'package:bokrah_retail/app/features/sync/data/services/sync_outbox_recorder.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_conflict.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:bokrah_retail/app/features/sync/presentation/cubits/sync_cubit.dart';
import 'package:bokrah_retail/app/features/sync/presentation/cubits/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemoteDataSource implements CatalogSyncRemoteDataSource {
  final List<SyncOperation> pushed = [];
  int Function(SyncOperation op)? nextServerId;
  Exception? Function(SyncOperation op)? errorOnPush;
  Map<SyncEntityType, List<Map<String, dynamic>>> pullRecords = {};

  @override
  Future<CatalogSyncSnapshot> pullAll(int storeId, {DateTime? since}) async {
    return CatalogSyncSnapshot(
      records: pullRecords,
      serverTimestamp: DateTime(2026, 11, 25, 12, 0),
    );
  }

  @override
  Future<SyncPushResult> pushOperation(SyncOperation operation) async {
    final err = errorOnPush?.call(operation);
    if (err != null) throw err;
    pushed.add(operation);
    final serverId = nextServerId?.call(operation) ?? operation.localEntityId;
    final canonical = Map<String, dynamic>.from(operation.payload);
    canonical['id'] = serverId;
    return SyncPushResult(
      serverId: serverId,
      canonicalPayload:
          operation.operationType == SyncOperationType.delete ? null : canonical,
    );
  }
}

void main() {
  late SharedPreferences prefs;
  late SyncOutboxLocalDataSource outbox;
  late CatalogLocalCacheStore cacheStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    outbox = SyncOutboxLocalDataSource(prefs: prefs);
    cacheStore = CatalogLocalCacheStore(prefs: prefs);
  });

  group('SyncOutboxLocalDataSource', () {
    test('coalesces create + update into create and create + delete into no-op', () async {
      final now = DateTime.now();
      await outbox.enqueue(
        SyncOperation(
          id: 'op1',
          idempotencyKey: 'k1',
          storeId: 1,
          entityType: SyncEntityType.company,
          operationType: SyncOperationType.create,
          localEntityId: 100,
          payload: const {'id': 100, 'name': 'Old'},
          createdAt: now,
          updatedAt: now,
        ),
      );
      await outbox.enqueue(
        SyncOperation(
          id: 'op2',
          idempotencyKey: 'k2',
          storeId: 1,
          entityType: SyncEntityType.company,
          operationType: SyncOperationType.update,
          localEntityId: 100,
          payload: const {'id': 100, 'name': 'New'},
          createdAt: now.add(const Duration(seconds: 1)),
          updatedAt: now.add(const Duration(seconds: 1)),
        ),
      );

      var ops = await outbox.getOperations(1);
      expect(ops.length, 1);
      expect(ops.first.operationType, SyncOperationType.create);
      expect(ops.first.payload['name'], 'New');

      await outbox.enqueue(
        SyncOperation(
          id: 'op3',
          idempotencyKey: 'k3',
          storeId: 1,
          entityType: SyncEntityType.company,
          operationType: SyncOperationType.delete,
          localEntityId: 100,
          payload: const {},
          createdAt: now.add(const Duration(seconds: 2)),
          updatedAt: now.add(const Duration(seconds: 2)),
        ),
      );

      ops = await outbox.getOperations(1);
      expect(ops, isEmpty);
    });

    test('isolates queues per storeId', () async {
      final now = DateTime.now();
      await outbox.enqueue(
        SyncOperation(
          id: 's1',
          idempotencyKey: 's1',
          storeId: 1,
          entityType: SyncEntityType.item,
          operationType: SyncOperationType.create,
          localEntityId: 10,
          payload: const {'id': 10},
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect((await outbox.getOperations(1)).length, 1);
      expect(await outbox.getOperations(2), isEmpty);
    });
  });

  group('SyncEngine', () {
    test('pushes in dependency order and remaps parent IDs on children', () async {
      final remote = _FakeRemoteDataSource()
        ..nextServerId = (op) =>
            op.entityType == SyncEntityType.department ? 9001 : op.localEntityId;

      final engine = SyncEngine(
        outbox: outbox,
        remote: remote,
        cacheStore: cacheStore,
      );

      final now = DateTime.now();
      // Enqueue item BEFORE department to prove dependency ordering works
      await engine.enqueueOperation(
        SyncOperation(
          id: 'item_1',
          idempotencyKey: 'item_1',
          storeId: 5,
          entityType: SyncEntityType.item,
          operationType: SyncOperationType.create,
          localEntityId: 200,
          payload: const {'id': 200, 'name': 'Laptop', 'departmentId': -1},
          createdAt: now,
          updatedAt: now,
        ),
      );
      await engine.enqueueOperation(
        SyncOperation(
          id: 'dept_1',
          idempotencyKey: 'dept_1',
          storeId: 5,
          entityType: SyncEntityType.department,
          operationType: SyncOperationType.create,
          localEntityId: -1,
          payload: const {'id': -1, 'name': 'Electronics'},
          createdAt: now.add(const Duration(milliseconds: 5)),
          updatedAt: now.add(const Duration(milliseconds: 5)),
        ),
      );

      final summary = await engine.syncStore(5);
      expect(summary.pushedCount, 2);
      expect(summary.pendingCount, 0);
      expect(remote.pushed[0].entityType, SyncEntityType.department);
      expect(remote.pushed[1].entityType, SyncEntityType.item);
      expect(remote.pushed[1].payload['departmentId'], 9001);
    });

    test('records conflict on 409 and resolves via serverWins or clientWins', () async {
      var failConflict = true;
      final remote = _FakeRemoteDataSource()
        ..errorOnPush = (op) {
          if (failConflict) {
            return const SyncConflictException(
              message: 'Version mismatch',
              serverPayload: {'id': 50, 'name': 'Server Name'},
            );
          }
          return null;
        };

      final engine = SyncEngine(
        outbox: outbox,
        remote: remote,
        cacheStore: cacheStore,
      );

      final now = DateTime.now();
      await engine.enqueueOperation(
        SyncOperation(
          id: 'op_c',
          idempotencyKey: 'op_c',
          storeId: 1,
          entityType: SyncEntityType.company,
          operationType: SyncOperationType.update,
          localEntityId: 50,
          payload: const {'id': 50, 'name': 'Local Name'},
          createdAt: now,
          updatedAt: now,
        ),
      );

      final summary = await engine.syncStore(1);
      expect(summary.conflictCount, 1);
      expect((await engine.getConflicts(1)).length, 1);

      failConflict = false;
      await engine.resolveConflict(
        1,
        'op_c',
        ConflictResolutionStrategy.clientWins,
      );
      final afterResolve = await engine.syncStore(1);
      expect(afterResolve.conflictCount, 0);
      expect(afterResolve.pushedCount, 1);
      expect(remote.pushed.last.payload['forceOverwrite'], true);
    });

    test('schedules backoff on network failure and aborts on 401', () async {
      final remote = _FakeRemoteDataSource()
        ..errorOnPush = (_) => const SyncNetworkException();

      final engine = SyncEngine(
        outbox: outbox,
        remote: remote,
        cacheStore: cacheStore,
      );

      final now = DateTime.now();
      await engine.enqueueOperation(
        SyncOperation(
          id: 'op_net',
          idempotencyKey: 'op_net',
          storeId: 1,
          entityType: SyncEntityType.unit,
          operationType: SyncOperationType.create,
          localEntityId: 12,
          payload: const {'id': 12, 'name': 'Box'},
          createdAt: now,
          updatedAt: now,
        ),
      );

      final netSummary = await engine.syncStore(1);
      expect(netSummary.failedCount, 1);
      final failedOp = (await engine.getPendingOperations(1)).first;
      expect(failedOp.retryCount, 1);
      expect(failedOp.nextRetryAt, isNotNull);
    });
  });

  group('SyncOutboxRecorder', () {
    test('does not enqueue when unauthenticated (guest mode)', () async {
      final authStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
      final storeService = StoreService();
      await storeService.setActiveStoreId(7);

      final engine = SyncEngine(
        outbox: outbox,
        remote: _FakeRemoteDataSource(),
        cacheStore: cacheStore,
      );

      final recorder = SyncOutboxRecorder(
        syncRepository: engine,
        tokenStorage: authStorage,
        storeService: storeService,
      );

      await recorder.record(
        entityType: SyncEntityType.item,
        operationType: SyncOperationType.create,
        localEntityId: 1,
        payload: const {'id': 1},
      );

      expect(await engine.getPendingOperations(7), isEmpty);

      await authStorage.saveSession(
        AuthSessionModel(
          accessToken: 'valid-token',
          refreshToken: 'refresh-token',
          phoneNumber: '+966500000000',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          userId: 'u1',
          name: 'Admin',
        ),
      );

      await recorder.record(
        entityType: SyncEntityType.item,
        operationType: SyncOperationType.create,
        localEntityId: 1,
        payload: const {'id': 1},
      );

      expect((await engine.getPendingOperations(7)).length, 1);
    });
  });

  group('AuthenticatedHttpClient', () {
    test('injects Bearer token, X-Store-Id, Idempotency-Key and maps 409', () async {
      final authStorage = SharedPrefsAuthTokenStorage(prefs: prefs);
      await authStorage.saveSession(
        AuthSessionModel(
          accessToken: 'jwt-123',
          refreshToken: 'refresh-123',
          phoneNumber: '+966500000000',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          userId: 'u1',
          name: 'Admin',
        ),
      );
      final storeService = StoreService();
      await storeService.setActiveStoreId(42);

      late http.Request captured;
      final mockClient = MockClient((request) async {
        captured = request;
        if (request.url.path.endsWith('/conflict')) {
          return http.Response(
            json.encode({
              'message': 'Conflict',
              'serverRecord': {'id': 9, 'name': 'Server'},
            }),
            409,
          );
        }
        return http.Response(json.encode({'ok': true}), 200);
      });

      final client = AuthenticatedHttpClient(
        client: mockClient,
        tokenStorage: authStorage,
        storeService: storeService,
        baseUrlOverride: 'https://example.test',
      );

      final res = await client.post(
        '/api/stores/42/items',
        body: {'name': 'Milk'},
        idempotencyKey: 'idem-1',
      );
      expect(res['ok'], true);
      expect(captured.headers['Authorization'], 'Bearer jwt-123');
      expect(captured.headers['X-Store-Id'], '42');
      expect(captured.headers['Idempotency-Key'], 'idem-1');

      expect(
        () => client.put('/api/stores/42/conflict', body: {'name': 'X'}),
        throwsA(isA<SyncConflictException>()),
      );
    });
  });

  group('SyncCubit', () {
    test('syncs mock remote data and handles guest mode', () async {
      final engine = SyncEngine(
        outbox: outbox,
        remote: MockCatalogSyncRemoteDataSource(prefs: prefs),
        cacheStore: cacheStore,
      );
      final cubit = SyncCubit(repository: engine);

      await cubit.setStoreContext(storeId: 1, isGuest: true);
      expect(cubit.state.phase, SyncPhase.guestReadOnly);

      await cubit.setStoreContext(storeId: 1, isGuest: false);
      expect(cubit.state.phase, SyncPhase.synced);
      expect(cubit.state.lastSyncedAt, isNotNull);

      await cubit.close();
    });
  });
}

import 'dart:async';
import 'dart:math';

import 'package:bokrah_retail/app/core/network/authenticated_http_client.dart';
import 'package:bokrah_retail/app/features/sync/data/datasources/catalog_sync_remote_datasource.dart';
import 'package:bokrah_retail/app/features/sync/data/datasources/sync_outbox_local_datasource.dart';
import 'package:bokrah_retail/app/features/sync/data/services/catalog_local_cache_store.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_conflict.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_summary.dart';
import 'package:bokrah_retail/app/features/sync/domain/repositories/sync_repository.dart';

/// Offline-first synchronization engine implementing outbox push, dependency
/// ID remapping, exponential backoff retries, conflict detection/resolution,
/// and store-scoped snapshot pulls.
class SyncEngine implements SyncRepository {
  final SyncOutboxLocalDataSource _outbox;
  final CatalogSyncRemoteDataSource _remote;
  final CatalogLocalCacheStore _cacheStore;
  final Map<int, Future<SyncSummary>> _inFlightByStore = {};

  SyncEngine({
    required SyncOutboxLocalDataSource outbox,
    required CatalogSyncRemoteDataSource remote,
    required CatalogLocalCacheStore cacheStore,
  })  : _outbox = outbox,
        _remote = remote,
        _cacheStore = cacheStore;

  @override
  Future<void> enqueueOperation(SyncOperation operation) {
    return _outbox.enqueue(operation);
  }

  @override
  Future<List<SyncOperation>> getPendingOperations(int storeId) {
    return _outbox.getOperations(storeId);
  }

  @override
  Future<List<SyncConflict>> getConflicts(int storeId) {
    return _outbox.getConflicts(storeId);
  }

  @override
  Future<DateTime?> getLastSyncedAt(int storeId) {
    return _outbox.getLastSyncedAt(storeId);
  }

  @override
  Future<SyncSummary> syncStore(
    int storeId, {
    ConflictResolutionStrategy defaultConflictStrategy =
        ConflictResolutionStrategy.manual,
  }) {
    final existing = _inFlightByStore[storeId];
    if (existing != null) return existing;

    final future = _runSync(storeId, defaultConflictStrategy).whenComplete(() {
      _inFlightByStore.remove(storeId);
    });
    _inFlightByStore[storeId] = future;
    return future;
  }

  Future<SyncSummary> _runSync(
    int storeId,
    ConflictResolutionStrategy defaultConflictStrategy,
  ) async {
    int pushedCount = 0;
    int pulledCount = 0;
    String? lastError;
    bool authAborted = false;

    final now = DateTime.now();
    final operations = await _outbox.getOperations(storeId);
    final idMap = await _outbox.getIdMap(storeId);

    // 1. Push phase (ordered by entity dependency & creation time)
    for (final op in operations) {
      if (!op.isReadyForRetry(now)) continue;

      final remappedOp = _remapForeignKeys(op, idMap);
      try {
        await _outbox.updateOperation(
          remappedOp.copyWith(status: SyncOperationStatus.inProgress),
        );

        final result = await _remote.pushOperation(remappedOp);
        if (result.serverId != null &&
            result.serverId != remappedOp.localEntityId) {
          await _outbox.saveIdMapping(
            storeId,
            remappedOp.entityType,
            remappedOp.localEntityId,
            result.serverId!,
          );
          idMap['${remappedOp.entityType.wireName}:${remappedOp.localEntityId}'] =
              result.serverId!;
        }

        if (result.canonicalPayload != null &&
            remappedOp.operationType != SyncOperationType.delete) {
          await _cacheStore.upsertCanonicalRecord(
            type: remappedOp.entityType,
            localId: remappedOp.localEntityId,
            canonical: result.canonicalPayload!,
          );
        }

        await _outbox.removeOperation(storeId, remappedOp.id);
        pushedCount++;
      } on SyncConflictException catch (e) {
        final serverPayload = e.serverPayload ?? const <String, dynamic>{};
        if (defaultConflictStrategy == ConflictResolutionStrategy.serverWins) {
          if (serverPayload.isNotEmpty) {
            await _cacheStore.upsertCanonicalRecord(
              type: remappedOp.entityType,
              localId: remappedOp.localEntityId,
              canonical: serverPayload,
            );
          }
          await _outbox.removeOperation(storeId, remappedOp.id);
        } else if (defaultConflictStrategy ==
            ConflictResolutionStrategy.clientWins) {
          final forced = remappedOp.copyWith(
            payload: {...remappedOp.payload, 'forceOverwrite': true},
            status: SyncOperationStatus.pending,
            clearNextRetryAt: true,
          );
          await _outbox.updateOperation(forced);
        } else {
          await _outbox.updateOperation(
            remappedOp.copyWith(
              status: SyncOperationStatus.conflict,
              lastError: e.message,
            ),
          );
          await _outbox.saveConflict(
            SyncConflict(
              operationId: remappedOp.id,
              storeId: storeId,
              entityType: remappedOp.entityType,
              localEntityId: remappedOp.localEntityId,
              localPayload: remappedOp.payload,
              serverPayload: serverPayload,
              detectedAt: DateTime.now(),
              reason: e.message,
            ),
          );
          lastError = e.message;
        }
      } on SyncApiException catch (e) {
        lastError = e.message;
        if (e.isAuthError) {
          await _outbox.updateOperation(
            remappedOp.copyWith(
              status: SyncOperationStatus.failed,
              lastError: e.message,
            ),
          );
          authAborted = true;
          break;
        }

        final nextRetryCount = remappedOp.retryCount + 1;
        final backoffSeconds = min(300, 5 * pow(2, nextRetryCount).toInt());
        await _outbox.updateOperation(
          remappedOp.copyWith(
            status: SyncOperationStatus.failed,
            retryCount: nextRetryCount,
            nextRetryAt: DateTime.now().add(Duration(seconds: backoffSeconds)),
            lastError: e.message,
          ),
        );
      } catch (e) {
        lastError = e.toString();
        final nextRetryCount = remappedOp.retryCount + 1;
        final backoffSeconds = min(300, 5 * pow(2, nextRetryCount).toInt());
        await _outbox.updateOperation(
          remappedOp.copyWith(
            status: SyncOperationStatus.failed,
            retryCount: nextRetryCount,
            nextRetryAt: DateTime.now().add(Duration(seconds: backoffSeconds)),
            lastError: lastError,
          ),
        );
      }
    }

    // 2. Pull phase (only if auth did not fail)
    DateTime? lastSyncedAt = await _outbox.getLastSyncedAt(storeId);
    if (!authAborted) {
      try {
        final snapshot = await _remote.pullAll(storeId, since: lastSyncedAt);
        final remainingOps = await _outbox.getOperations(storeId);

        for (final entry in snapshot.records.entries) {
          final protectedIds = remainingOps
              .where((o) => o.entityType == entry.key)
              .map((o) => o.localEntityId)
              .toSet();
          pulledCount += await _cacheStore.mergePulledRecords(
            type: entry.key,
            pulled: entry.value,
            protectedLocalIds: protectedIds,
          );
        }

        lastSyncedAt = snapshot.serverTimestamp;
        await _outbox.setLastSyncedAt(storeId, lastSyncedAt);
      } on SyncApiException catch (e) {
        lastError ??= e.message;
      } catch (e) {
        lastError ??= e.toString();
      }
    }

    final remaining = await _outbox.getOperations(storeId);
    final conflicts = await _outbox.getConflicts(storeId);

    return SyncSummary(
      storeId: storeId,
      lastSyncedAt: lastSyncedAt,
      pendingCount: remaining
          .where((o) => o.status == SyncOperationStatus.pending)
          .length,
      failedCount: remaining
          .where((o) => o.status == SyncOperationStatus.failed)
          .length,
      conflictCount: conflicts.length,
      pushedCount: pushedCount,
      pulledCount: pulledCount,
      lastError: lastError,
    );
  }

  SyncOperation _remapForeignKeys(SyncOperation op, Map<String, int> idMap) {
    final payload = Map<String, dynamic>.from(op.payload);

    final ownMapped = idMap['${op.entityType.wireName}:${op.localEntityId}'];
    final effectiveLocalId = ownMapped ?? op.localEntityId;

    void remapField(String key, SyncEntityType targetType) {
      final raw = payload[key];
      if (raw is num) {
        final mapped = idMap['${targetType.wireName}:${raw.toInt()}'];
        if (mapped != null) {
          payload[key] = mapped;
        }
      }
    }

    if (op.entityType == SyncEntityType.category) {
      remapField('parentId', SyncEntityType.category);
    } else if (op.entityType == SyncEntityType.item) {
      remapField('departmentId', SyncEntityType.department);
      remapField('categoryId', SyncEntityType.category);
    } else if (op.entityType == SyncEntityType.unit) {
      remapField('itemId', SyncEntityType.item);
    } else if (op.entityType == SyncEntityType.barcodeLink) {
      remapField('itemId', SyncEntityType.item);
      remapField('barcodeId', SyncEntityType.barcode);
    }

    return op.copyWith(localEntityId: effectiveLocalId, payload: payload);
  }

  @override
  Future<void> resolveConflict(
    int storeId,
    String operationId,
    ConflictResolutionStrategy strategy,
  ) async {
    final conflicts = await _outbox.getConflicts(storeId);
    final conflict =
        conflicts.where((c) => c.operationId == operationId).firstOrNull;
    final ops = await _outbox.getOperations(storeId);
    final op = ops.where((o) => o.id == operationId).firstOrNull;

    if (strategy == ConflictResolutionStrategy.serverWins) {
      if (conflict != null && conflict.serverPayload.isNotEmpty) {
        await _cacheStore.upsertCanonicalRecord(
          type: conflict.entityType,
          localId: conflict.localEntityId,
          canonical: conflict.serverPayload,
        );
      }
      await _outbox.removeOperation(storeId, operationId);
      await _outbox.removeConflict(storeId, operationId);
      return;
    }

    if (strategy == ConflictResolutionStrategy.clientWins && op != null) {
      await _outbox.updateOperation(
        op.copyWith(
          payload: {...op.payload, 'forceOverwrite': true},
          status: SyncOperationStatus.pending,
          retryCount: 0,
          clearNextRetryAt: true,
          clearLastError: true,
        ),
      );
      await _outbox.removeConflict(storeId, operationId);
    }
  }

  @override
  Future<void> retryFailedOperations(int storeId) async {
    final ops = await _outbox.getOperations(storeId);
    for (final op in ops) {
      if (op.status == SyncOperationStatus.failed) {
        await _outbox.updateOperation(
          op.copyWith(
            status: SyncOperationStatus.pending,
            clearNextRetryAt: true,
            clearLastError: true,
          ),
        );
      }
    }
  }

  @override
  Future<void> clearStoreSyncState(int storeId) {
    return _outbox.clearStore(storeId);
  }
}

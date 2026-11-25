import 'package:bokrah_retail/app/features/sync/domain/entities/sync_conflict.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_summary.dart';

/// Contract for offline-first store synchronization.
abstract class SyncRepository {
  /// Enqueues an offline-first mutation for [storeId].
  Future<void> enqueueOperation(SyncOperation operation);

  /// Returns all queued operations for [storeId] sorted by dependency & creation time.
  Future<List<SyncOperation>> getPendingOperations(int storeId);

  /// Returns all unresolved conflicts for [storeId].
  Future<List<SyncConflict>> getConflicts(int storeId);

  /// Returns the last successful sync timestamp for [storeId], if any.
  Future<DateTime?> getLastSyncedAt(int storeId);

  /// Runs a full push (outbox) + pull (remote snapshot) cycle for [storeId].
  Future<SyncSummary> syncStore(
    int storeId, {
    ConflictResolutionStrategy defaultConflictStrategy =
        ConflictResolutionStrategy.manual,
  });

  /// Resolves a specific conflict using [strategy].
  Future<void> resolveConflict(
    int storeId,
    String operationId,
    ConflictResolutionStrategy strategy,
  );

  /// Resets retry timers on failed operations so they are retried immediately.
  Future<void> retryFailedOperations(int storeId);

  /// Clears queued sync state for [storeId].
  Future<void> clearStoreSyncState(int storeId);
}

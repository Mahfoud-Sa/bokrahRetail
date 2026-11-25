import 'dart:async';

import 'package:bokrah_retail/app/features/sync/domain/entities/sync_conflict.dart';
import 'package:bokrah_retail/app/features/sync/domain/repositories/sync_repository.dart';
import 'package:bokrah_retail/app/features/sync/presentation/cubits/sync_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates offline-first store synchronization, background retry timer,
/// store switching, and manual conflict resolution.
class SyncCubit extends Cubit<SyncState> {
  final SyncRepository _repository;
  final Duration _backgroundInterval;
  Timer? _retryTimer;

  SyncCubit({
    required SyncRepository repository,
    Duration backgroundInterval = const Duration(seconds: 30),
  })  : _repository = repository,
        _backgroundInterval = backgroundInterval,
        super(const SyncState());

  /// Updates the active store context and refreshes queued sync state.
  ///
  /// When [isGuest] is true, synchronization is disabled (read-only guest mode).
  Future<void> setStoreContext({
    required int? storeId,
    required bool isGuest,
    bool triggerSync = true,
  }) async {
    if (isGuest || storeId == null) {
      _stopBackgroundTimer();
      emit(
        SyncState(
          activeStoreId: storeId,
          phase: isGuest ? SyncPhase.guestReadOnly : SyncPhase.idle,
          autoSyncEnabled: state.autoSyncEnabled,
        ),
      );
      return;
    }

    await loadStoreQueue(storeId);
    _startBackgroundTimerIfNeeded();

    if (triggerSync) {
      await syncNow();
    }
  }

  Future<void> loadStoreQueue(int storeId) async {
    final ops = await _repository.getPendingOperations(storeId);
    final conflicts = await _repository.getConflicts(storeId);
    final lastSyncedAt = await _repository.getLastSyncedAt(storeId);

    final nextPhase = conflicts.isNotEmpty
        ? SyncPhase.conflict
        : (state.phase == SyncPhase.syncing ? SyncPhase.syncing : SyncPhase.idle);

    emit(
      state.copyWith(
        activeStoreId: storeId,
        pendingOperations: ops,
        conflicts: conflicts,
        lastSyncedAt: lastSyncedAt,
        phase: nextPhase,
      ),
    );
  }

  /// Triggers an immediate push + pull synchronization for the active Store.
  Future<void> syncNow({
    ConflictResolutionStrategy defaultConflictStrategy =
        ConflictResolutionStrategy.manual,
  }) async {
    final storeId = state.activeStoreId;
    if (storeId == null || state.phase == SyncPhase.guestReadOnly) return;
    if (state.phase == SyncPhase.syncing) return;

    emit(state.copyWith(phase: SyncPhase.syncing, clearLastError: true));

    final summary = await _repository.syncStore(
      storeId,
      defaultConflictStrategy: defaultConflictStrategy,
    );

    // Guard against store switch occurring while sync was in flight
    if (state.activeStoreId != storeId) return;

    final ops = await _repository.getPendingOperations(storeId);
    final conflicts = await _repository.getConflicts(storeId);

    SyncPhase resolvedPhase;
    if (conflicts.isNotEmpty) {
      resolvedPhase = SyncPhase.conflict;
    } else if (summary.hasError) {
      resolvedPhase = SyncPhase.offlineOrError;
    } else {
      resolvedPhase = SyncPhase.synced;
    }

    emit(
      state.copyWith(
        phase: resolvedPhase,
        pendingOperations: ops,
        conflicts: conflicts,
        lastSyncedAt: summary.lastSyncedAt,
        lastError: summary.lastError,
        clearLastError: !summary.hasError,
      ),
    );
  }

  Future<void> retryFailed() async {
    final storeId = state.activeStoreId;
    if (storeId == null || state.phase == SyncPhase.guestReadOnly) return;
    await _repository.retryFailedOperations(storeId);
    await syncNow();
  }

  Future<void> resolveConflict(
    String operationId,
    ConflictResolutionStrategy strategy,
  ) async {
    final storeId = state.activeStoreId;
    if (storeId == null) return;
    await _repository.resolveConflict(storeId, operationId, strategy);
    await syncNow();
  }

  void setAutoSync(bool enabled) {
    emit(state.copyWith(autoSyncEnabled: enabled));
    if (enabled) {
      _startBackgroundTimerIfNeeded();
    } else {
      _stopBackgroundTimer();
    }
  }

  void _startBackgroundTimerIfNeeded() {
    _stopBackgroundTimer();
    if (!state.autoSyncEnabled ||
        state.activeStoreId == null ||
        state.phase == SyncPhase.guestReadOnly) {
      return;
    }
    _retryTimer = Timer.periodic(_backgroundInterval, (_) {
      if (state.pendingCount > 0 || state.failedCount > 0) {
        syncNow();
      }
    });
  }

  void _stopBackgroundTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  @override
  Future<void> close() {
    _stopBackgroundTimer();
    return super.close();
  }
}

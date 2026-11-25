import 'package:bokrah_retail/app/features/sync/domain/entities/sync_conflict.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:equatable/equatable.dart';

enum SyncPhase {
  idle,
  syncing,
  synced,
  offlineOrError,
  conflict,
  guestReadOnly,
}

class SyncState extends Equatable {
  final int? activeStoreId;
  final SyncPhase phase;
  final List<SyncOperation> pendingOperations;
  final List<SyncConflict> conflicts;
  final DateTime? lastSyncedAt;
  final String? lastError;
  final bool autoSyncEnabled;

  const SyncState({
    this.activeStoreId,
    this.phase = SyncPhase.idle,
    this.pendingOperations = const [],
    this.conflicts = const [],
    this.lastSyncedAt,
    this.lastError,
    this.autoSyncEnabled = true,
  });

  int get pendingCount => pendingOperations
      .where((o) => o.status != SyncOperationStatus.conflict)
      .length;

  int get failedCount => pendingOperations
      .where((o) => o.status == SyncOperationStatus.failed)
      .length;

  int get conflictCount => conflicts.length;

  SyncState copyWith({
    int? activeStoreId,
    bool clearActiveStoreId = false,
    SyncPhase? phase,
    List<SyncOperation>? pendingOperations,
    List<SyncConflict>? conflicts,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    String? lastError,
    bool clearLastError = false,
    bool? autoSyncEnabled,
  }) {
    return SyncState(
      activeStoreId:
          clearActiveStoreId ? null : (activeStoreId ?? this.activeStoreId),
      phase: phase ?? this.phase,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      conflicts: conflicts ?? this.conflicts,
      lastSyncedAt:
          clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
    );
  }

  @override
  List<Object?> get props => [
        activeStoreId,
        phase,
        pendingOperations,
        conflicts,
        lastSyncedAt,
        lastError,
        autoSyncEnabled,
      ];
}

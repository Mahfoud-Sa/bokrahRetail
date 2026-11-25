import 'package:equatable/equatable.dart';

/// Aggregated synchronization status for a single Store.
class SyncSummary extends Equatable {
  final int storeId;
  final DateTime? lastSyncedAt;
  final int pendingCount;
  final int failedCount;
  final int conflictCount;
  final int pushedCount;
  final int pulledCount;
  final String? lastError;

  const SyncSummary({
    required this.storeId,
    this.lastSyncedAt,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.conflictCount = 0,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.lastError,
  });

  bool get hasPendingWork => pendingCount > 0 || failedCount > 0;
  bool get hasConflicts => conflictCount > 0;
  bool get hasError => lastError != null && lastError!.isNotEmpty;

  @override
  List<Object?> get props => [
        storeId,
        lastSyncedAt,
        pendingCount,
        failedCount,
        conflictCount,
        pushedCount,
        pulledCount,
        lastError,
      ];
}

import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:equatable/equatable.dart';

/// Strategy for resolving a detected synchronization conflict.
enum ConflictResolutionStrategy {
  serverWins,
  clientWins,
  manual,
}

/// Represents a version or state conflict between a local outbox mutation and
/// the canonical server record.
class SyncConflict extends Equatable {
  final String operationId;
  final int storeId;
  final SyncEntityType entityType;
  final int localEntityId;
  final Map<String, dynamic> localPayload;
  final Map<String, dynamic> serverPayload;
  final DateTime detectedAt;
  final String reason;

  const SyncConflict({
    required this.operationId,
    required this.storeId,
    required this.entityType,
    required this.localEntityId,
    required this.localPayload,
    required this.serverPayload,
    required this.detectedAt,
    this.reason = 'Server record was modified after local edit.',
  });

  Map<String, dynamic> toMap() {
    return {
      'operationId': operationId,
      'storeId': storeId,
      'entityType': entityType.wireName,
      'localEntityId': localEntityId,
      'localPayload': localPayload,
      'serverPayload': serverPayload,
      'detectedAt': detectedAt.toIso8601String(),
      'reason': reason,
    };
  }

  factory SyncConflict.fromMap(Map<String, dynamic> map) {
    return SyncConflict(
      operationId: map['operationId']?.toString() ?? '',
      storeId: (map['storeId'] as num?)?.toInt() ?? 0,
      entityType: SyncEntityType.fromWireName(map['entityType']?.toString() ?? ''),
      localEntityId: (map['localEntityId'] as num?)?.toInt() ?? 0,
      localPayload: Map<String, dynamic>.from(map['localPayload'] as Map? ?? const {}),
      serverPayload: Map<String, dynamic>.from(map['serverPayload'] as Map? ?? const {}),
      detectedAt: DateTime.tryParse(map['detectedAt']?.toString() ?? '') ?? DateTime.now(),
      reason: map['reason']?.toString() ?? 'Sync conflict detected.',
    );
  }

  @override
  List<Object?> get props => [
        operationId,
        storeId,
        entityType,
        localEntityId,
        localPayload,
        serverPayload,
        detectedAt,
        reason,
      ];
}

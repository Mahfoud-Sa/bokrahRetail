import 'package:equatable/equatable.dart';

/// Catalog and operational entity types supported by synchronization.
///
/// Ordered by dependency priority so parent records sync before children.
enum SyncEntityType {
  department(0, 'departments'),
  category(1, 'categories'),
  company(2, 'companies'),
  unit(3, 'units'),
  item(4, 'items'),
  barcode(5, 'barcodes'),
  barcodeLink(6, 'barcode_links');

  final int dependencyOrder;
  final String wireName;

  const SyncEntityType(this.dependencyOrder, this.wireName);

  static SyncEntityType fromWireName(String value) {
    return SyncEntityType.values.firstWhere(
      (e) => e.wireName == value || e.name == value,
      orElse: () => SyncEntityType.item,
    );
  }
}

enum SyncOperationType {
  create,
  update,
  delete;

  static SyncOperationType fromName(String value) {
    return SyncOperationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncOperationType.update,
    );
  }
}

enum SyncOperationStatus {
  pending,
  inProgress,
  failed,
  conflict;

  static SyncOperationStatus fromName(String value) {
    return SyncOperationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncOperationStatus.pending,
    );
  }
}

/// An offline-first outbox mutation waiting to be synchronized with the backend.
class SyncOperation extends Equatable {
  final String id;
  final String idempotencyKey;
  final int storeId;
  final SyncEntityType entityType;
  final SyncOperationType operationType;
  final int localEntityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final SyncOperationStatus status;
  final int? baseVersion;

  const SyncOperation({
    required this.id,
    required this.idempotencyKey,
    required this.storeId,
    required this.entityType,
    required this.operationType,
    required this.localEntityId,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.retryCount = 0,
    this.nextRetryAt,
    this.lastError,
    this.status = SyncOperationStatus.pending,
    this.baseVersion,
  });

  bool isReadyForRetry(DateTime now) {
    if (status == SyncOperationStatus.conflict) return false;
    if (nextRetryAt == null) return true;
    return !now.isBefore(nextRetryAt!);
  }

  SyncOperation copyWith({
    String? id,
    String? idempotencyKey,
    int? storeId,
    SyncEntityType? entityType,
    SyncOperationType? operationType,
    int? localEntityId,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? retryCount,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
    String? lastError,
    bool clearLastError = false,
    SyncOperationStatus? status,
    int? baseVersion,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      storeId: storeId ?? this.storeId,
      entityType: entityType ?? this.entityType,
      operationType: operationType ?? this.operationType,
      localEntityId: localEntityId ?? this.localEntityId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      status: status ?? this.status,
      baseVersion: baseVersion ?? this.baseVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idempotencyKey': idempotencyKey,
      'storeId': storeId,
      'entityType': entityType.wireName,
      'operationType': operationType.name,
      'localEntityId': localEntityId,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'retryCount': retryCount,
      'nextRetryAt': nextRetryAt?.toIso8601String(),
      'lastError': lastError,
      'status': status.name,
      'baseVersion': baseVersion,
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id']?.toString() ?? '',
      idempotencyKey: map['idempotencyKey']?.toString() ?? '',
      storeId: (map['storeId'] as num?)?.toInt() ?? 0,
      entityType: SyncEntityType.fromWireName(map['entityType']?.toString() ?? ''),
      operationType: SyncOperationType.fromName(map['operationType']?.toString() ?? ''),
      localEntityId: (map['localEntityId'] as num?)?.toInt() ?? 0,
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? const {}),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      nextRetryAt: map['nextRetryAt'] != null
          ? DateTime.tryParse(map['nextRetryAt'].toString())
          : null,
      lastError: map['lastError']?.toString(),
      status: SyncOperationStatus.fromName(map['status']?.toString() ?? ''),
      baseVersion: (map['baseVersion'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        idempotencyKey,
        storeId,
        entityType,
        operationType,
        localEntityId,
        payload,
        createdAt,
        updatedAt,
        retryCount,
        nextRetryAt,
        lastError,
        status,
        baseVersion,
      ];
}

import 'dart:convert';

import 'package:bokrah_retail/app/features/sync/domain/entities/sync_conflict.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists store-scoped outbox operations, conflicts, ID mappings, and
/// last-sync timestamps in [SharedPreferences].
class SyncOutboxLocalDataSource {
  final SharedPreferences? _prefs;

  SyncOutboxLocalDataSource({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ?? await SharedPreferences.getInstance();

  String _outboxKey(int storeId) => 'sync_outbox_store_$storeId';
  String _conflictsKey(int storeId) => 'sync_conflicts_store_$storeId';
  String _idMapKey(int storeId) => 'sync_id_map_store_$storeId';
  String _lastSyncKey(int storeId) => 'sync_last_at_store_$storeId';

  Future<List<SyncOperation>> getOperations(int storeId) async {
    final prefs = await _instance;
    final raw = prefs.getStringList(_outboxKey(storeId)) ?? const [];
    final ops = raw
        .map((s) => SyncOperation.fromMap(json.decode(s) as Map<String, dynamic>))
        .toList();

    ops.sort((a, b) {
      final orderCmp =
          a.entityType.dependencyOrder.compareTo(b.entityType.dependencyOrder);
      if (orderCmp != 0) return orderCmp;
      return a.createdAt.compareTo(b.createdAt);
    });
    return ops;
  }

  Future<void> _saveOperations(int storeId, List<SyncOperation> ops) async {
    final prefs = await _instance;
    await prefs.setStringList(
      _outboxKey(storeId),
      ops.map((o) => json.encode(o.toMap())).toList(),
    );
  }

  /// Enqueues [operation] while coalescing redundant pending mutations for the
  /// same entity within the same store.
  Future<void> enqueue(SyncOperation operation) async {
    final ops = await getOperations(operation.storeId);
    final existingIdx = ops.indexWhere(
      (o) =>
          o.entityType == operation.entityType &&
          o.localEntityId == operation.localEntityId &&
          o.status != SyncOperationStatus.conflict,
    );

    if (existingIdx == -1) {
      ops.add(operation);
      await _saveOperations(operation.storeId, ops);
      return;
    }

    final existing = ops[existingIdx];

    if (existing.operationType == SyncOperationType.create) {
      if (operation.operationType == SyncOperationType.delete) {
        // Never pushed to server -> drop the pending create altogether.
        ops.removeAt(existingIdx);
      } else {
        // Coalesce create + update into a single create with latest payload.
        ops[existingIdx] = existing.copyWith(
          payload: operation.payload,
          updatedAt: operation.updatedAt,
          status: SyncOperationStatus.pending,
          clearNextRetryAt: true,
          clearLastError: true,
        );
      }
    } else if (existing.operationType == SyncOperationType.update) {
      if (operation.operationType == SyncOperationType.delete) {
        ops[existingIdx] = existing.copyWith(
          operationType: SyncOperationType.delete,
          payload: operation.payload,
          updatedAt: operation.updatedAt,
          status: SyncOperationStatus.pending,
          clearNextRetryAt: true,
          clearLastError: true,
        );
      } else {
        ops[existingIdx] = existing.copyWith(
          payload: operation.payload,
          updatedAt: operation.updatedAt,
          status: SyncOperationStatus.pending,
          clearNextRetryAt: true,
          clearLastError: true,
        );
      }
    } else {
      // Existing is delete; if recreated locally with same ID, turn into update.
      ops[existingIdx] = operation;
    }

    await _saveOperations(operation.storeId, ops);
  }

  Future<void> updateOperation(SyncOperation operation) async {
    final ops = await getOperations(operation.storeId);
    final idx = ops.indexWhere((o) => o.id == operation.id);
    if (idx != -1) {
      ops[idx] = operation;
      await _saveOperations(operation.storeId, ops);
    }
  }

  Future<void> removeOperation(int storeId, String operationId) async {
    final ops = await getOperations(storeId);
    ops.removeWhere((o) => o.id == operationId);
    await _saveOperations(storeId, ops);
  }

  Future<List<SyncConflict>> getConflicts(int storeId) async {
    final prefs = await _instance;
    final raw = prefs.getStringList(_conflictsKey(storeId)) ?? const [];
    return raw
        .map((s) => SyncConflict.fromMap(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveConflict(SyncConflict conflict) async {
    final conflicts = await getConflicts(conflict.storeId);
    conflicts.removeWhere((c) => c.operationId == conflict.operationId);
    conflicts.add(conflict);
    final prefs = await _instance;
    await prefs.setStringList(
      _conflictsKey(conflict.storeId),
      conflicts.map((c) => json.encode(c.toMap())).toList(),
    );
  }

  Future<void> removeConflict(int storeId, String operationId) async {
    final conflicts = await getConflicts(storeId);
    conflicts.removeWhere((c) => c.operationId == operationId);
    final prefs = await _instance;
    await prefs.setStringList(
      _conflictsKey(storeId),
      conflicts.map((c) => json.encode(c.toMap())).toList(),
    );
  }

  Future<Map<String, int>> getIdMap(int storeId) async {
    final prefs = await _instance;
    final raw = prefs.getString(_idMapKey(storeId));
    if (raw == null || raw.isEmpty) return {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<void> saveIdMapping(
    int storeId,
    SyncEntityType entityType,
    int localId,
    int serverId,
  ) async {
    final map = await getIdMap(storeId);
    map['${entityType.wireName}:$localId'] = serverId;
    final prefs = await _instance;
    await prefs.setString(_idMapKey(storeId), json.encode(map));
  }

  Future<int?> getServerId(
    int storeId,
    SyncEntityType entityType,
    int localId,
  ) async {
    final map = await getIdMap(storeId);
    return map['${entityType.wireName}:$localId'];
  }

  Future<DateTime?> getLastSyncedAt(int storeId) async {
    final prefs = await _instance;
    final raw = prefs.getString(_lastSyncKey(storeId));
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  Future<void> setLastSyncedAt(int storeId, DateTime timestamp) async {
    final prefs = await _instance;
    await prefs.setString(_lastSyncKey(storeId), timestamp.toIso8601String());
  }

  Future<void> clearStore(int storeId) async {
    final prefs = await _instance;
    await prefs.remove(_outboxKey(storeId));
    await prefs.remove(_conflictsKey(storeId));
    await prefs.remove(_idMapKey(storeId));
    await prefs.remove(_lastSyncKey(storeId));
  }
}

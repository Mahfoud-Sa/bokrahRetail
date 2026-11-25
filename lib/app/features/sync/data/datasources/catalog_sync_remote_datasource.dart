import 'dart:convert';

import 'package:bokrah_retail/app/core/network/authenticated_http_client.dart';
import 'package:bokrah_retail/app/features/sync/domain/entities/sync_operation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Server snapshot returned by a pull synchronization call.
class CatalogSyncSnapshot {
  final Map<SyncEntityType, List<Map<String, dynamic>>> records;
  final DateTime serverTimestamp;

  const CatalogSyncSnapshot({
    required this.records,
    required this.serverTimestamp,
  });
}

/// Result returned when pushing an individual outbox operation to the backend.
class SyncPushResult {
  final int? serverId;
  final Map<String, dynamic>? canonicalPayload;

  const SyncPushResult({
    this.serverId,
    this.canonicalPayload,
  });
}

/// Remote synchronization contract for store-scoped catalog data.
abstract class CatalogSyncRemoteDataSource {
  Future<CatalogSyncSnapshot> pullAll(int storeId, {DateTime? since});
  Future<SyncPushResult> pushOperation(SyncOperation operation);
}

/// HTTP-backed remote synchronization datasource.
///
/// Uses [AuthenticatedHttpClient] so every request includes the Bearer token,
/// `X-Store-Id`, and `Idempotency-Key`.
class ApiCatalogSyncRemoteDataSource implements CatalogSyncRemoteDataSource {
  final AuthenticatedHttpClient _httpClient;

  ApiCatalogSyncRemoteDataSource({
    required AuthenticatedHttpClient httpClient,
  }) : _httpClient = httpClient;

  @override
  Future<CatalogSyncSnapshot> pullAll(int storeId, {DateTime? since}) async {
    final query = since != null ? {'since': since.toIso8601String()} : null;
    final data = await _httpClient.get(
      '/api/stores/$storeId/sync/pull',
      storeId: storeId,
      queryParameters: query,
    );

    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final records = <SyncEntityType, List<Map<String, dynamic>>>{};

    for (final type in SyncEntityType.values) {
      final rawList = map[type.wireName];
      if (rawList is List) {
        records[type] = rawList
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    final ts = map['serverTimestamp'] != null
        ? DateTime.tryParse(map['serverTimestamp'].toString()) ?? DateTime.now()
        : DateTime.now();

    return CatalogSyncSnapshot(records: records, serverTimestamp: ts);
  }

  @override
  Future<SyncPushResult> pushOperation(SyncOperation operation) async {
    final storeId = operation.storeId;
    final resource = operation.entityType.wireName;
    final basePath = '/api/stores/$storeId/$resource';

    dynamic response;
    switch (operation.operationType) {
      case SyncOperationType.create:
        response = await _httpClient.post(
          basePath,
          storeId: storeId,
          body: operation.payload,
          idempotencyKey: operation.idempotencyKey,
        );
        break;
      case SyncOperationType.update:
        response = await _httpClient.put(
          '$basePath/${operation.localEntityId}',
          storeId: storeId,
          body: operation.payload,
          idempotencyKey: operation.idempotencyKey,
        );
        break;
      case SyncOperationType.delete:
        response = await _httpClient.delete(
          '$basePath/${operation.localEntityId}',
          storeId: storeId,
          idempotencyKey: operation.idempotencyKey,
        );
        return const SyncPushResult();
    }

    if (response is Map<String, dynamic>) {
      return SyncPushResult(
        serverId: (response['id'] as num?)?.toInt() ?? operation.localEntityId,
        canonicalPayload: response,
      );
    }

    return SyncPushResult(serverId: operation.localEntityId);
  }
}

/// Local mock simulator of the remote store backend for `USE_MOCK_AUTH=true`
/// and offline-first integration testing.
class MockCatalogSyncRemoteDataSource implements CatalogSyncRemoteDataSource {
  final SharedPreferences? _prefs;
  final Set<String> _processedIdempotencyKeys = {};

  MockCatalogSyncRemoteDataSource({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ?? await SharedPreferences.getInstance();

  String _remoteKey(int storeId, SyncEntityType type) =>
      'mock_remote_store_${storeId}_${type.wireName}';

  Future<List<Map<String, dynamic>>> _loadRemoteList(
    int storeId,
    SyncEntityType type,
  ) async {
    final prefs = await _instance;
    final raw = prefs.getStringList(_remoteKey(storeId, type)) ?? const [];
    return raw
        .map((s) => Map<String, dynamic>.from(json.decode(s) as Map))
        .toList();
  }

  Future<void> _saveRemoteList(
    int storeId,
    SyncEntityType type,
    List<Map<String, dynamic>> list,
  ) async {
    final prefs = await _instance;
    await prefs.setStringList(
      _remoteKey(storeId, type),
      list.map((m) => json.encode(m)).toList(),
    );
  }

  @override
  Future<CatalogSyncSnapshot> pullAll(int storeId, {DateTime? since}) async {
    final records = <SyncEntityType, List<Map<String, dynamic>>>{};
    for (final type in SyncEntityType.values) {
      records[type] = await _loadRemoteList(storeId, type);
    }
    return CatalogSyncSnapshot(
      records: records,
      serverTimestamp: DateTime.now(),
    );
  }

  @override
  Future<SyncPushResult> pushOperation(SyncOperation operation) async {
    final list = await _loadRemoteList(operation.storeId, operation.entityType);

    if (_processedIdempotencyKeys.contains(operation.idempotencyKey)) {
      final existing = list.where((m) => m['id'] == operation.localEntityId).firstOrNull;
      return SyncPushResult(
        serverId: operation.localEntityId,
        canonicalPayload: existing,
      );
    }

    _processedIdempotencyKeys.add(operation.idempotencyKey);

    switch (operation.operationType) {
      case SyncOperationType.create:
        final payload = Map<String, dynamic>.from(operation.payload);
        final assignedId = (payload['id'] as num?)?.toInt() ??
            DateTime.now().microsecondsSinceEpoch;
        payload['id'] = assignedId;
        list.removeWhere((m) => m['id'] == assignedId);
        list.add(payload);
        await _saveRemoteList(operation.storeId, operation.entityType, list);
        return SyncPushResult(
          serverId: assignedId,
          canonicalPayload: payload,
        );

      case SyncOperationType.update:
        final payload = Map<String, dynamic>.from(operation.payload);
        payload['id'] = operation.localEntityId;
        final idx = list.indexWhere((m) => m['id'] == operation.localEntityId);
        if (idx != -1) {
          list[idx] = payload;
        } else {
          list.add(payload);
        }
        await _saveRemoteList(operation.storeId, operation.entityType, list);
        return SyncPushResult(
          serverId: operation.localEntityId,
          canonicalPayload: payload,
        );

      case SyncOperationType.delete:
        if (operation.entityType == SyncEntityType.barcodeLink) {
          list.removeWhere(
            (m) =>
                m['itemId'] == operation.payload['itemId'] &&
                m['barcodeId'] == operation.payload['barcodeId'],
          );
        } else {
          list.removeWhere((m) => m['id'] == operation.localEntityId);
        }
        await _saveRemoteList(operation.storeId, operation.entityType, list);
        return const SyncPushResult();
    }
  }
}

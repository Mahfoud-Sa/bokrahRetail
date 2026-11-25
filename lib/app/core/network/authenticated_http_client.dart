import 'dart:convert';
import 'dart:io';

import 'package:bokrah_retail/app/config/app_config.dart';
import 'package:bokrah_retail/app/features/auth/data/datasources/auth_token_storage.dart';
import 'package:bokrah_retail/app/features/store/data/services/store_service.dart';
import 'package:http/http.dart' as http;

/// Typed exception hierarchy for authenticated backend requests.
class SyncApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? responseBody;

  const SyncApiException(
    this.message, {
    this.statusCode,
    this.responseBody,
  });

  /// True when the failure is transient and safe to retry later.
  bool get isTransient =>
      statusCode == null || statusCode == 408 || statusCode == 429 || (statusCode! >= 500);

  /// True when the user must re-authenticate or lacks permission.
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'SyncApiException($statusCode): $message';
}

class SyncUnauthorizedException extends SyncApiException {
  const SyncUnauthorizedException([
    super.message = 'Unauthorized: Missing or expired authentication token.',
  ]) : super(statusCode: 401);
}

class SyncForbiddenException extends SyncApiException {
  const SyncForbiddenException([
    super.message = 'Forbidden: Insufficient permissions for this store.',
  ]) : super(statusCode: 403);
}

class SyncConflictException extends SyncApiException {
  final Map<String, dynamic>? serverPayload;

  const SyncConflictException({
    String message = 'Sync conflict detected with server record.',
    this.serverPayload,
  }) : super(message, statusCode: 409, responseBody: serverPayload);
}

class SyncValidationException extends SyncApiException {
  const SyncValidationException(
    super.message, {
    super.responseBody,
  }) : super(statusCode: 400);
}

class SyncNetworkException extends SyncApiException {
  const SyncNetworkException([
    super.message = 'Network unreachable. Changes will sync when online.',
  ]);
}

/// Shared authenticated HTTP boundary for store-scoped operational requests.
///
/// Automatically attaches the Bearer token, active `X-Store-Id` header,
/// and optional `Idempotency-Key` header, and maps HTTP errors consistently.
class AuthenticatedHttpClient {
  final http.Client _client;
  final AuthTokenStorage _tokenStorage;
  final StoreService _storeService;
  final String _baseUrl;

  AuthenticatedHttpClient({
    http.Client? client,
    required AuthTokenStorage tokenStorage,
    required StoreService storeService,
    String? baseUrlOverride,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage,
        _storeService = storeService,
        _baseUrl = baseUrlOverride ?? AppConfig.apiBaseUrl;

  Future<Map<String, String>> _buildHeaders({
    int? storeIdOverride,
    String? idempotencyKey,
  }) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const SyncUnauthorizedException();
    }

    final storeId = storeIdOverride ?? await _storeService.getActiveStoreId();
    if (storeId == null) {
      throw const SyncForbiddenException('No active store selected.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Store-Id': '$storeId',
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'Idempotency-Key': idempotencyKey,
    };
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final normalizedBase = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath')
        .replace(queryParameters: queryParameters);
  }

  Future<dynamic> get(
    String path, {
    int? storeId,
    Map<String, String>? queryParameters,
  }) async {
    final headers = await _buildHeaders(storeIdOverride: storeId);
    final uri = _buildUri(path, queryParameters);
    return _send(() => _client.get(uri, headers: headers));
  }

  Future<dynamic> post(
    String path, {
    int? storeId,
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    final headers = await _buildHeaders(
      storeIdOverride: storeId,
      idempotencyKey: idempotencyKey,
    );
    final uri = _buildUri(path);
    return _send(
      () => _client.post(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    int? storeId,
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    final headers = await _buildHeaders(
      storeIdOverride: storeId,
      idempotencyKey: idempotencyKey,
    );
    final uri = _buildUri(path);
    return _send(
      () => _client.put(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ),
    );
  }

  Future<dynamic> delete(
    String path, {
    int? storeId,
    String? idempotencyKey,
  }) async {
    final headers = await _buildHeaders(
      storeIdOverride: storeId,
      idempotencyKey: idempotencyKey,
    );
    final uri = _buildUri(path);
    return _send(() => _client.delete(uri, headers: headers));
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      return _parseResponse(response);
    } on SyncApiException {
      rethrow;
    } on SocketException {
      throw const SyncNetworkException();
    } on http.ClientException catch (e) {
      throw SyncNetworkException(e.message);
    }
  }

  dynamic _parseResponse(http.Response response) {
    final status = response.statusCode;
    final bodyText = response.body.trim();
    dynamic decoded;
    if (bodyText.isNotEmpty) {
      try {
        decoded = json.decode(bodyText);
      } catch (_) {
        decoded = null;
      }
    }

    if (status >= 200 && status < 300) {
      return decoded;
    }

    final map = decoded is Map<String, dynamic> ? decoded : null;
    final msg = map?['message']?.toString() ??
        map?['title']?.toString() ??
        'Request failed with status $status';

    switch (status) {
      case 400:
      case 422:
        throw SyncValidationException(msg, responseBody: map);
      case 401:
        throw SyncUnauthorizedException(msg);
      case 403:
        throw SyncForbiddenException(msg);
      case 409:
        throw SyncConflictException(
          message: msg,
          serverPayload: map?['serverRecord'] is Map<String, dynamic>
              ? map!['serverRecord'] as Map<String, dynamic>
              : map,
        );
      default:
        throw SyncApiException(msg, statusCode: status, responseBody: map);
    }
  }
}

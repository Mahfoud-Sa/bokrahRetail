import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config/app_config.dart';
import '../../../auth/data/datasources/auth_token_storage.dart';
import '../models/store_dto.dart';
import '../models/store_rbac_models.dart';
import 'store_service.dart';

class StoreApiException implements Exception {
  final String message;
  final int? statusCode;

  const StoreApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class StoreValidationException extends StoreApiException {
  final Map<String, List<String>>? fieldErrors;

  const StoreValidationException([
    super.message = 'Store name (or Arabic/English name) is required.',
    this.fieldErrors,
  ]) : super(statusCode: 400);
}

class StoreUnauthorizedException extends StoreApiException {
  const StoreUnauthorizedException([
    super.message = 'Unauthorized: Missing or expired authentication token.',
  ]) : super(statusCode: 401);
}

class StoreForbiddenException extends StoreApiException {
  const StoreForbiddenException([
    super.message = 'Access Denied: Only store Owner or Manager has permission to access this resource.',
  ]) : super(statusCode: 403);
}

class StoreNotFoundException extends StoreApiException {
  const StoreNotFoundException([
    super.message = 'Store does not exist or has been deleted.',
  ]) : super(statusCode: 404);
}

class StoreOwnerAlreadyHasStoreException extends StoreApiException {
  const StoreOwnerAlreadyHasStoreException([
    super.message = 'A store owner can only add one store.',
  ]) : super(statusCode: 409);
}

class StoreDuplicateNameException extends StoreApiException {
  const StoreDuplicateNameException([
    super.message = 'A store with the same name already exists.',
  ]) : super(statusCode: 409);
}

class StoreServerException extends StoreApiException {
  const StoreServerException([
    super.message = 'Something went wrong. Please try again later.',
  ]) : super(statusCode: 500);
}

abstract class StoreApiService {
  /// POST /api/stores: Creates a new tenant store and assigns current user as Owner
  Future<StoreResponseDto> createStore(CreateStoreRequest request);

  /// GET /api/stores: Lists all stores accessible to current authenticated user
  Future<List<StoreResponseDto>> getMyStores();

  /// GET /api/stores/{storeId}: Retrieves details of a specific store by ID
  Future<StoreResponseDto> getStoreById(int storeId);

  /// GET /api/stores/permissions/catalog: Fetches all available permission descriptors
  Future<List<StorePermissionDto>> getPermissionCatalog();

  /// GET /api/stores/{storeId}/roles: Lists all custom roles in a store
  Future<List<StoreRoleDto>> getStoreRoles(int storeId);

  /// POST /api/stores/{storeId}/roles: Creates a new custom role in a store
  Future<StoreRoleDto> createStoreRole(int storeId, CreateStoreRoleRequest request);

  /// PUT /api/stores/{storeId}/roles/{roleId}: Updates an existing store role
  Future<StoreRoleDto> updateStoreRole(int storeId, int roleId, UpdateStoreRoleRequest request);

  /// DELETE /api/stores/{storeId}/roles/{roleId}: Deletes a custom store role
  Future<void> deleteStoreRole(int storeId, int roleId);

  /// GET /api/stores/{storeId}/members: Lists all members in a store
  Future<List<StoreMemberDto>> getStoreMembers(int storeId);

  /// POST /api/stores/{storeId}/members/provision: Provisions a new or existing user as member
  Future<StoreMemberDto> provisionMember(int storeId, ProvisionStoreMemberRequest request);

  /// POST /api/stores/{storeId}/members: Adds an existing user by ID to the store
  Future<StoreMemberDto> addMember(int storeId, AddStoreMemberRequest request);

  /// PUT /api/stores/{storeId}/members/{userId}/roles: Updates assigned custom roles for a member
  Future<StoreMemberDto> updateMemberRoles(int storeId, int userId, UpdateMemberRolesRequest request);

  /// DELETE /api/stores/{storeId}/members/{userId}: Removes a member from the store
  Future<void> removeMember(int storeId, int userId);
}

class ApiStoreService implements StoreApiService {
  final http.Client _client;
  final AuthTokenStorage _tokenStorage;
  final StoreService? _storeService;
  final String? _baseUrlOverride;
  final String _defaultEndpoint;

  ApiStoreService({
    http.Client? client,
    required AuthTokenStorage tokenStorage,
    StoreService? storeService,
    String? baseUrlOverride,
    String defaultEndpoint = '/api/stores',
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage,
        _storeService = storeService,
        _baseUrlOverride = baseUrlOverride,
        _defaultEndpoint = defaultEndpoint;

  String get _baseUrl => _baseUrlOverride ?? AppConfig.apiBaseUrl;

  Future<String> _getAuthToken() async {
    final session = await _tokenStorage.getSession();
    final token = session?.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw const StoreUnauthorizedException();
    }
    return token;
  }

  @override
  Future<StoreResponseDto> createStore(
    CreateStoreRequest request, {
    String? endpoint,
  }) async {
    if (!request.hasValidName) {
      throw const StoreValidationException();
    }

    final token = await _getAuthToken();
    final session = await _tokenStorage.getSession();
    final roles = session?.roles.map((r) => r.toLowerCase()).toList() ?? [];
    final hasPermission = roles.contains('store') ||
        roles.contains('admin') ||
        roles.contains('owner') ||
        roles.isEmpty; // backend will assign Owner
    if (!hasPermission) {
      throw const StoreForbiddenException();
    }

    final path = endpoint ?? _defaultEndpoint;
    final uri = Uri.parse('$_baseUrl$path');
    http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // Never send ownerUserId or sensitive auth data in request bodies
        body: json.encode(request.toJson()),
      );
    } catch (e) {
      if (e is! http.ClientException && e is! FormatException && e is! Exception) {
        rethrow;
      }
      throw const StoreServerException();
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded is Map<String, dynamic> && decoded.containsKey('data')
          ? decoded['data'] as Map<String, dynamic>
          : decoded as Map<String, dynamic>;
      final parsed = StoreResponseDto.fromJson(data);
      if (_storeService != null) {
        await _storeService.updateStoreInfo(parsed.toEntity());
        await _storeService.setHasRegisteredStore(true);
        await _storeService.setActiveStoreId(parsed.id);
      }
      return parsed;
    }

    final errorModel = _extractApiError(response.body);
    final msg = errorModel.formattedErrorMessage;

    if (response.statusCode == 400) {
      throw StoreValidationException(
        msg.isNotEmpty ? msg : 'Store name (or Arabic/English name) is required.',
        errorModel.errors,
      );
    }

    if (response.statusCode == 401) {
      throw const StoreUnauthorizedException();
    }

    if (response.statusCode == 403) {
      throw StoreForbiddenException(
        msg.isNotEmpty ? msg : 'Only admin and store owner can add a store.',
      );
    }

    if (response.statusCode == 409) {
      if (msg.contains('only add one') ||
          msg.contains('already has') ||
          msg.contains('يملك') ||
          msg.contains('مسجل بالفعل')) {
        throw StoreOwnerAlreadyHasStoreException(msg.isNotEmpty
            ? msg
            : 'A store owner can only add one store.');
      }
      if (msg.toLowerCase().contains('already exists') ||
          msg.toLowerCase().contains('duplicate') ||
          msg.contains('مكرر') ||
          msg.contains('موجود مسبقاً')) {
        throw StoreDuplicateNameException(msg.isNotEmpty
            ? msg
            : 'A store with the same name already exists.');
      }
      throw StoreOwnerAlreadyHasStoreException(msg.isNotEmpty
          ? msg
          : 'A store owner can only add one store.');
    }

    throw StoreServerException(
      msg.isNotEmpty ? msg : 'Server error with status code ${response.statusCode}',
    );
  }

  @override
  Future<List<StoreResponseDto>> getMyStores() async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl$_defaultEndpoint');
    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      if (e is! http.ClientException && e is! FormatException && e is! Exception) {
        rethrow;
      }
      throw const StoreServerException();
    }

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final rawList = decoded is List
          ? decoded
          : (decoded is Map<String, dynamic> && decoded['data'] is List
              ? decoded['data'] as List
              : [decoded]);

      final stores = rawList
          .map((item) => StoreResponseDto.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      if (_storeService != null && stores.isNotEmpty) {
        await _storeService.cacheAccessibleStores(stores.map((s) => s.toEntity()).toList());
      }

      return stores;
    }

    if (response.statusCode == 401) {
      throw const StoreUnauthorizedException();
    }

    final errorModel = _extractApiError(response.body);
    throw StoreServerException(
      errorModel.message ?? 'Failed to load accessible stores (${response.statusCode})',
    );
  }

  @override
  Future<StoreResponseDto> getStoreById(int storeId) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl$_defaultEndpoint/$storeId');
    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      if (e is! http.ClientException && e is! FormatException && e is! Exception) {
        rethrow;
      }
      throw const StoreServerException();
    }

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded is Map<String, dynamic> && decoded.containsKey('data')
          ? decoded['data'] as Map<String, dynamic>
          : decoded as Map<String, dynamic>;
      final store = StoreResponseDto.fromJson(data);
      return store;
    }

    if (response.statusCode == 401) {
      throw const StoreUnauthorizedException();
    }

    if (response.statusCode == 403) {
      throw const StoreForbiddenException(
        'Access Denied: Only store Owner or Manager can view store details.',
      );
    }

    if (response.statusCode == 404) {
      throw const StoreNotFoundException(
        'Store does not exist or has been deleted.',
      );
    }

    final errorModel = _extractApiError(response.body);
    throw StoreServerException(
      errorModel.message ?? 'Failed to get store details (${response.statusCode})',
    );
  }

  ApiErrorResponse _extractApiError(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return ApiErrorResponse.fromJson(decoded);
      }
    } catch (_) {}
    return const ApiErrorResponse();
  }

  void _throwIfError(http.Response response, String fallbackMessage) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final errorModel = _extractApiError(response.body);
    final msg = errorModel.formattedErrorMessage.isNotEmpty
        ? errorModel.formattedErrorMessage
        : (errorModel.message ?? fallbackMessage);

    if (response.statusCode == 400) {
      throw StoreValidationException(msg, errorModel.errors);
    }
    if (response.statusCode == 401) {
      throw const StoreUnauthorizedException();
    }
    if (response.statusCode == 403) {
      throw StoreForbiddenException(msg);
    }
    if (response.statusCode == 404) {
      throw StoreNotFoundException(msg);
    }
    if (response.statusCode == 409) {
      throw StoreDuplicateNameException(msg);
    }
    throw StoreServerException(msg);
  }

  @override
  Future<List<StorePermissionDto>> getPermissionCatalog() async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl$_defaultEndpoint/permissions/catalog');
    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw const StoreServerException();
    }

    _throwIfError(response, 'Failed to fetch permission catalog');
    final decoded = json.decode(response.body);
    final rawList = decoded is List ? decoded : (decoded['data'] as List? ?? []);
    return rawList
        .map((item) => StorePermissionDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<List<StoreRoleDto>> getStoreRoles(int storeId) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl$_defaultEndpoint/$storeId/roles');
    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw const StoreServerException();
    }

    _throwIfError(response, 'Failed to fetch store roles');
    final decoded = json.decode(response.body);
    final rawList = decoded is List ? decoded : (decoded['data'] as List? ?? []);
    return rawList
        .map((item) => StoreRoleDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<StoreRoleDto> createStoreRole(int storeId, CreateStoreRoleRequest request) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl$_defaultEndpoint/$storeId/roles');
    http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );
    } catch (e) {
      throw const StoreServerException();
    }

    _throwIfError(response, 'Failed to create store role');
    final decoded = json.decode(response.body);
    final data = decoded is Map<String, dynamic> && decoded.containsKey('data')
        ? decoded['data'] as Map<String, dynamic>
        : decoded as Map<String, dynamic>;
    return StoreRoleDto.fromJson(data);
  }

  @override
  Future<StoreRoleDto> updateStoreRole(
    int storeId,
    int roleId,
    UpdateStoreRoleRequest request,
  ) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl$_defaultEndpoint/$storeId/roles/$roleId');
    http.Response response;
    try {
      response = await _client.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );
    } catch (e) {
      throw const StoreServerException();
    }

    _throwIfError(response, 'Failed to update store role');
    final decoded = json.decode(response.body);
    final data = decoded is Map<String, dynamic> && decoded.containsKey('data')
        ? decoded['data'] as Map<String, dynamic>
        : decoded as Map<String, dynamic>;
    return StoreRoleDto.fromJson(data);
  }

  @override
  Future<void> deleteStoreRole(int storeId, int roleId) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl$_defaultEndpoint/$storeId/roles/$roleId');
    http.Response response;
    try {
      response = await _client.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw const StoreServerException();
    }

    _throwIfError(response, 'Failed to delete store role');
  }

  @override
  Future<List<StoreMemberDto>> getStoreMembers(int storeId) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl$_defaultEndpoint/$storeId/members');
    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw const StoreServerException();
    }

    _throwIfError(response, 'Failed to fetch store members');
    final decoded = json.decode(response.body);
    final rawList = decoded is List ? decoded : (decoded['data'] as List? ?? []);
    return rawList
        .map((item) => StoreMemberDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<StoreMemberDto> provisionMember(
    int storeId,
    ProvisionStoreMemberRequest request,
  ) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl$_defaultEndpoint/$storeId/members/provision');
    http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );
    } catch (e) {
      throw const StoreServerException();
    }

    _throwIfError(response, 'Failed to provision member');
    final decoded = json.decode(response.body);
    final data = decoded is Map<String, dynamic> && decoded.containsKey('data')
        ? decoded['data'] as Map<String, dynamic>
        : decoded as Map<String, dynamic>;
    return StoreMemberDto.fromJson(data);
  }

  @override
  Future<StoreMemberDto> addMember(
    int storeId,
    AddStoreMemberRequest request,
  ) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl$_defaultEndpoint/$storeId/members');
    http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );
    } catch (e) {
      throw const StoreServerException();
    }

    _throwIfError(response, 'Failed to add member');
    final decoded = json.decode(response.body);
    final data = decoded is Map<String, dynamic> && decoded.containsKey('data')
        ? decoded['data'] as Map<String, dynamic>
        : decoded as Map<String, dynamic>;
    return StoreMemberDto.fromJson(data);
  }

  @override
  Future<StoreMemberDto> updateMemberRoles(
    int storeId,
    int userId,
    UpdateMemberRolesRequest request,
  ) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl$_defaultEndpoint/$storeId/members/$userId/roles');
    http.Response response;
    try {
      response = await _client.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );
    } catch (e) {
      throw const StoreServerException();
    }

    _throwIfError(response, 'Failed to update member roles');
    final decoded = json.decode(response.body);
    final data = decoded is Map<String, dynamic> && decoded.containsKey('data')
        ? decoded['data'] as Map<String, dynamic>
        : decoded as Map<String, dynamic>;
    return StoreMemberDto.fromJson(data);
  }

  @override
  Future<void> removeMember(int storeId, int userId) async {
    final token = await _getAuthToken();
    final uri = Uri.parse('$_baseUrl$_defaultEndpoint/$storeId/members/$userId');
    http.Response response;
    try {
      response = await _client.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw const StoreServerException();
    }

    _throwIfError(response, 'Failed to remove member');
  }
}

class MockStoreApiService implements StoreApiService {
  final AuthTokenStorage _tokenStorage;
  final StoreService? _storeService;
  final List<StoreResponseDto> _mockStores = [];
  final Set<String> _existingNames = {
    'متجر بكرة للإلكترونيات',
    'bokrah electronics',
    'متجر القدس',
  };
  final Set<String> _ownersWithStore = {};
  Duration simulatedLatency;

  MockStoreApiService({
    required AuthTokenStorage tokenStorage,
    StoreService? storeService,
    this.simulatedLatency = const Duration(milliseconds: 100),
  })  : _tokenStorage = tokenStorage,
        _storeService = storeService {
    // Seed initial demo store
    _mockStores.add(const StoreResponseDto(
      id: 1,
      ownerUserId: 10,
      name: 'متجر بكرة للإلكترونيات والتجزئة',
      description: 'متجر متخصص في بيع وصيانة الأجهزة الإلكترونية والهواتف الذكية.',
      phoneNumber: '+962790000000',
      email: 'contact@bokrah.com',
      address: 'Amman, Jordan',
      currencyCode: 'JOD',
      isActive: true,
      createdAtUtc: '2026-11-08T14:30:00Z',
      currentUserRole: 'Owner',
    ));
  }

  void seedStores(List<StoreResponseDto> stores) {
    _mockStores.clear();
    _mockStores.addAll(stores);
  }

  void seedOwnerWithStore(String ownerIdOrEmail) {
    _ownersWithStore.add(ownerIdOrEmail.toLowerCase().trim());
  }

  void seedExistingStoreName(String name) {
    _existingNames.add(name.toLowerCase().trim());
  }

  @override
  Future<StoreResponseDto> createStore(CreateStoreRequest request) async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    if (!request.hasValidName) {
      throw const StoreValidationException();
    }

    final session = await _tokenStorage.getSession();
    if (session == null || session.accessToken.isEmpty) {
      throw const StoreUnauthorizedException();
    }

    final roles = session.roles.map((r) => r.toLowerCase()).toList();
    if (!roles.contains('store') &&
        !roles.contains('admin') &&
        !roles.contains('owner') &&
        roles.isNotEmpty) {
      throw const StoreForbiddenException();
    }

    final ownerKey = (session.email != null && session.email!.isNotEmpty
            ? session.email!
            : session.userId)
        .toLowerCase()
        .trim();

    if (roles.contains('store') && !roles.contains('admin')) {
      if (_ownersWithStore.contains(ownerKey)) {
        throw const StoreOwnerAlreadyHasStoreException();
      }
    }

    final checkNames = [
      if (request.name != null && request.name!.trim().isNotEmpty)
        request.name!.trim().toLowerCase(),
      if (request.nameAr != null && request.nameAr!.trim().isNotEmpty)
        request.nameAr!.trim().toLowerCase(),
      if (request.nameEn != null && request.nameEn!.trim().isNotEmpty)
        request.nameEn!.trim().toLowerCase(),
    ];

    for (final n in checkNames) {
      if (_existingNames.contains(n)) {
        throw const StoreDuplicateNameException();
      }
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final newId = 100 + _mockStores.length + 1;

    for (final n in checkNames) {
      _existingNames.add(n);
    }
    _ownersWithStore.add(ownerKey);

    final cleanPhone = request.effectivePhone ?? '';
    final response = StoreResponseDto(
      id: newId,
      ownerUserId: int.tryParse(session.userId) ?? 1,
      name: request.effectiveName.isNotEmpty
          ? request.effectiveName
          : 'Bokrah Retail Store',
      description: request.description?.trim(),
      phoneNumber: cleanPhone.isNotEmpty ? cleanPhone : null,
      email: request.email?.trim(),
      address: request.address?.trim(),
      currencyCode: request.currencyCode,
      isActive: request.isActive,
      createdAtUtc: now,
      currentUserRole: 'Owner', // User who creates a store is automatically assigned Owner
      nameAr: request.nameAr?.trim(),
      nameEn: request.nameEn?.trim(),
      slogan: request.slogan?.trim(),
      subtitle: request.subtitle?.trim(),
      businessType: request.businessType?.trim() ?? 'إلكترونيات وأجهزة ذكية',
      googleMapsUrl: request.googleMapsUrl?.trim(),
      latitude: request.latitude,
      longitude: request.longitude,
      websiteUrl: request.websiteUrl?.trim(),
      phoneNumbers: request.phoneNumbers ?? const [],
      ownerName: (session.name != null && session.name!.isNotEmpty)
          ? session.name!
          : (session.email ?? 'Ahmed Ali'),
    );

    _mockStores.add(response);

    if (_storeService != null) {
      await _storeService.setHasRegisteredStore(true, ownerKey);
      await _storeService.updateStoreInfo(response.toEntity());
      await _storeService.setActiveStoreId(newId);
    }

    return response;
  }

  @override
  Future<List<StoreResponseDto>> getMyStores() async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }
    final session = await _tokenStorage.getSession();
    if (session == null || session.accessToken.isEmpty) {
      throw const StoreUnauthorizedException();
    }
    return List<StoreResponseDto>.from(_mockStores);
  }

  @override
  Future<StoreResponseDto> getStoreById(int storeId) async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }
    final session = await _tokenStorage.getSession();
    if (session == null || session.accessToken.isEmpty) {
      throw const StoreUnauthorizedException();
    }

    final store = _mockStores.firstWhere(
      (s) => s.id == storeId,
      orElse: () => throw const StoreNotFoundException(),
    );

    if (store.currentUserRole == 'Staff') {
      throw const StoreForbiddenException(
        'Access Denied: Only store Owner or Manager can view store details.',
      );
    }

    return store;
  }

  @override
  Future<List<StorePermissionDto>> getPermissionCatalog() async {
    return const [
      StorePermissionDto(
        code: 'store.orders.view',
        name: 'View Orders',
        description: 'View orders',
        category: 'Orders',
      ),
      StorePermissionDto(
        code: 'store.orders.manage',
        name: 'Manage Orders',
        description: 'Manage orders',
        category: 'Orders',
      ),
      StorePermissionDto(
        code: 'store.invoices.view',
        name: 'View Invoices',
        description: 'View invoices',
        category: 'Finance',
      ),
      StorePermissionDto(
        code: 'store.invoices.manage',
        name: 'Manage Invoices',
        description: 'Manage invoices',
        category: 'Finance',
      ),
      StorePermissionDto(
        code: 'store.members.view',
        name: 'View Members',
        description: 'View store members',
        category: 'Members',
      ),
      StorePermissionDto(
        code: 'store.members.manage',
        name: 'Manage Members',
        description: 'Manage store members',
        category: 'Members',
      ),
      StorePermissionDto(
        code: 'store.roles.view',
        name: 'View Roles',
        description: 'View store roles',
        category: 'Roles',
      ),
      StorePermissionDto(
        code: 'store.roles.manage',
        name: 'Manage Roles',
        description: 'Manage store roles',
        category: 'Roles',
      ),
      StorePermissionDto(
        code: 'store.settings.manage',
        name: 'Manage Settings',
        description: 'Manage store settings',
        category: 'Settings',
      ),
      StorePermissionDto(
        code: 'store.reports.view',
        name: 'View Reports',
        description: 'View analytics and reports',
        category: 'Analytics',
      ),
    ];
  }

  @override
  Future<List<StoreRoleDto>> getStoreRoles(int storeId) async {
    return [
      StoreRoleDto(
        id: 1,
        storeId: storeId,
        name: 'Cashier',
        description: 'Cashier role',
        permissionCodes: const ['store.invoices.view', 'store.invoices.manage'],
        memberCount: 1,
        createdAtUtc: DateTime.now().toUtc(),
      ),
    ];
  }

  @override
  Future<StoreRoleDto> createStoreRole(
    int storeId,
    CreateStoreRoleRequest request,
  ) async {
    return StoreRoleDto(
      id: 2,
      storeId: storeId,
      name: request.name,
      description: request.description,
      permissionCodes: request.permissionCodes,
      memberCount: 0,
      createdAtUtc: DateTime.now().toUtc(),
    );
  }

  @override
  Future<StoreRoleDto> updateStoreRole(
    int storeId,
    int roleId,
    UpdateStoreRoleRequest request,
  ) async {
    return StoreRoleDto(
      id: roleId,
      storeId: storeId,
      name: request.name,
      description: request.description,
      permissionCodes: request.permissionCodes,
      memberCount: 0,
      createdAtUtc: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> deleteStoreRole(int storeId, int roleId) async {}

  @override
  Future<List<StoreMemberDto>> getStoreMembers(int storeId) async {
    return [
      StoreMemberDto(
        storeId: storeId,
        userId: 1,
        userEmail: 'owner@bokrah.com',
        userFullName: 'Owner',
        role: 'Owner',
        customRoleIds: const [],
        customRoles: const [],
        effectivePermissions: const ['store.orders.manage', 'store.roles.manage'],
        createdAtUtc: DateTime.now().toUtc(),
      ),
    ];
  }

  @override
  Future<StoreMemberDto> provisionMember(
    int storeId,
    ProvisionStoreMemberRequest request,
  ) async {
    return StoreMemberDto(
      storeId: storeId,
      userId: 99,
      userEmail: request.email,
      userFullName: request.fullName,
      role: request.role,
      customRoleIds: request.roleIds,
      customRoles: const ['Member'],
      effectivePermissions: const ['store.orders.view'],
      createdAtUtc: DateTime.now().toUtc(),
    );
  }

  @override
  Future<StoreMemberDto> addMember(
    int storeId,
    AddStoreMemberRequest request,
  ) async {
    return StoreMemberDto(
      storeId: storeId,
      userId: request.userId,
      userEmail: 'user@bokrah.com',
      userFullName: 'Member User',
      role: request.role,
      customRoleIds: request.roleIds,
      customRoles: const ['Member'],
      effectivePermissions: const ['store.orders.view'],
      createdAtUtc: DateTime.now().toUtc(),
    );
  }

  @override
  Future<StoreMemberDto> updateMemberRoles(
    int storeId,
    int userId,
    UpdateMemberRolesRequest request,
  ) async {
    return StoreMemberDto(
      storeId: storeId,
      userId: userId,
      userEmail: 'user@bokrah.com',
      userFullName: 'Member User',
      role: 'Member',
      customRoleIds: request.roleIds,
      customRoles: const ['CustomRole'],
      effectivePermissions: const ['store.orders.manage'],
      createdAtUtc: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> removeMember(int storeId, int userId) async {}
}

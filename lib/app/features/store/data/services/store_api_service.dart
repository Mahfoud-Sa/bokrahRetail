import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config/app_config.dart';
import '../../../auth/data/datasources/auth_token_storage.dart';
import '../models/store_dto.dart';
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

// Backward compatibility exception aliases
typedef RestaurantApiException = StoreApiException;
typedef RestaurantValidationException = StoreValidationException;
typedef RestaurantUnauthorizedException = StoreUnauthorizedException;
typedef RestaurantForbiddenException = StoreForbiddenException;
typedef RestaurantNotFoundException = StoreNotFoundException;
typedef RestaurantOwnerAlreadyHasRestaurantException = StoreOwnerAlreadyHasStoreException;
typedef RestaurantDuplicateNameException = StoreDuplicateNameException;
typedef RestaurantServerException = StoreServerException;

abstract class StoreApiService {
  /// POST /api/stores: Creates a new tenant store and assigns current user as Owner
  Future<StoreResponseDto> createStore(CreateStoreRequest request);

  /// GET /api/stores: Lists all stores accessible to current authenticated user
  Future<List<StoreResponseDto>> getMyStores();

  /// GET /api/stores/{storeId}: Retrieves details of a specific store by ID
  Future<StoreResponseDto> getStoreById(int storeId);

  // Backward compatibility alias
  Future<StoreResponseDto> createRestaurant(CreateStoreRequest request) =>
      createStore(request);
}

typedef RestaurantApiService = StoreApiService;

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
    StoreService? localRestaurantService,
    String? baseUrlOverride,
    String defaultEndpoint = '/api/stores',
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage,
        _storeService = storeService ?? localRestaurantService,
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
    final hasPermission = roles.contains('restaurant') ||
        roles.contains('store') ||
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

  @override
  Future<StoreResponseDto> createRestaurant(CreateStoreRequest request) =>
      createStore(request, endpoint: '/api/restaurants');

  ApiErrorResponse _extractApiError(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return ApiErrorResponse.fromJson(decoded);
      }
    } catch (_) {}
    return const ApiErrorResponse();
  }
}

class ApiRestaurantService extends ApiStoreService {
  ApiRestaurantService({
    super.client,
    required super.tokenStorage,
    super.baseUrlOverride,
    StoreService? storeService,
    StoreService? localRestaurantService,
  }) : super(
          storeService: storeService ?? localRestaurantService,
          defaultEndpoint: '/api/restaurants',
        );
}

class MockStoreApiService implements StoreApiService {
  final AuthTokenStorage _tokenStorage;
  final StoreService? _storeService;
  final List<StoreResponseDto> _mockStores = [];
  final Set<String> _existingNames = {
    'متجر بكرة للإلكترونيات',
    'bokrah electronics',
    'متجر القدس',
    'مطعم القدس',
    'al quds restaurant',
  };
  final Set<String> _ownersWithStore = {};
  Duration simulatedLatency;

  MockStoreApiService({
    required AuthTokenStorage tokenStorage,
    StoreService? storeService,
    StoreService? localRestaurantService,
    this.simulatedLatency = const Duration(milliseconds: 100),
  })  : _tokenStorage = tokenStorage,
        _storeService = storeService ?? localRestaurantService {
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

  void seedOwnerWithRestaurant(String ownerIdOrEmail) =>
      seedOwnerWithStore(ownerIdOrEmail);

  void seedExistingStoreName(String name) {
    _existingNames.add(name.toLowerCase().trim());
  }

  void seedExistingRestaurantName(String name) =>
      seedExistingStoreName(name);

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
    if (!roles.contains('restaurant') &&
        !roles.contains('store') &&
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

    if ((roles.contains('restaurant') || roles.contains('store')) &&
        !roles.contains('admin')) {
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
  Future<StoreResponseDto> createRestaurant(CreateStoreRequest request) =>
      createStore(request);
}

class MockRestaurantApiService extends MockStoreApiService {
  MockRestaurantApiService({
    required super.tokenStorage,
    super.storeService,
    super.localRestaurantService,
    super.simulatedLatency,
  });
}

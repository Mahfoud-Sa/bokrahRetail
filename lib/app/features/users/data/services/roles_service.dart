import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/app_config.dart';
import '../../../auth/data/datasources/auth_token_storage.dart';
import '../models/permission_model.dart';
import '../models/role_model.dart';

abstract class RolesService {
  Future<List<RoleModel>> getRoles();
  Future<RoleModel> createRole(String name, {List<int> permissionIds = const []});
  Future<RoleModel> updateRole(int id, String name, {List<int>? permissionIds});
  Future<bool> deleteRole(int id);
  Future<List<PermissionModel>> getPermissions();
  Future<bool> saveRolePermissions(int roleId, List<int> permissionIds);
}

class ApiRolesService implements RolesService {
  final http.Client _client;
  final AuthTokenStorage _tokenStorage;
  final String? _baseUrlOverride;

  static const String _cachedRolesKey = 'cached_system_roles_v1';
  static const String _cachedPermissionsKey = 'cached_system_permissions_v1';
  static const String _rolePermissionsMapKey = 'role_permissions_map_v1';

  ApiRolesService({
    http.Client? client,
    required AuthTokenStorage tokenStorage,
    String? baseUrlOverride,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage,
        _baseUrlOverride = baseUrlOverride;

  String get _baseUrl =>
      (_baseUrlOverride ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, String>> _headers({bool isJson = true}) async {
    final token = await _tokenStorage.getAccessToken();
    final headers = <String, String>{
      'accept': '*/*',
    };
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  Future<List<RoleModel>> getRoles() async {
    final uri = Uri.parse('$_baseUrl/api/Roles');
    final prefs = await SharedPreferences.getInstance();

    try {
      final headers = await _headers();
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          final roles = decoded
              .map((e) => RoleModel.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();

          // Merge locally saved permissions mapping for each role
          final rolePermMap = await _getRolePermissionsMap();
          final enrichedRoles = roles.map((r) {
            final savedPerms = rolePermMap[r.id.toString()];
            if (savedPerms != null && savedPerms.isNotEmpty) {
              return r.copyWith(permissionIds: savedPerms);
            }
            return r;
          }).toList();

          // Cache locally
          await _cacheRoles(enrichedRoles);
          return enrichedRoles;
        }
      }
    } catch (_) {
      // In case of network failure, fallback to cached or default
    }

    return _getCachedRoles();
  }

  @override
  Future<RoleModel> createRole(
    String name, {
    List<int> permissionIds = const [],
  }) async {
    final uri = Uri.parse('$_baseUrl/api/Roles');
    RoleModel? createdRole;

    try {
      final headers = await _headers();
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode({'name': name.trim()}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map) {
          createdRole = RoleModel.fromMap(
            Map<String, dynamic>.from(decoded),
          ).copyWith(permissionIds: permissionIds);
        }
      }
    } catch (_) {}

    // Fallback if offline / mock mode
    createdRole ??= RoleModel(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name.trim(),
      permissionIds: permissionIds,
      createdAt: DateTime.now().toIso8601String(),
    );

    if (permissionIds.isNotEmpty) {
      await saveRolePermissions(createdRole.id, permissionIds);
    }

    final currentRoles = await _getCachedRoles();
    currentRoles.removeWhere((r) => r.id == createdRole!.id);
    currentRoles.add(createdRole);
    await _cacheRoles(currentRoles);

    return createdRole;
  }

  @override
  Future<RoleModel> updateRole(
    int id,
    String name, {
    List<int>? permissionIds,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/Roles/$id');
    try {
      final headers = await _headers();
      await _client.put(
        uri,
        headers: headers,
        body: jsonEncode({'id': id, 'name': name.trim()}),
      );
    } catch (_) {}

    if (permissionIds != null) {
      await saveRolePermissions(id, permissionIds);
    }

    final currentRoles = await _getCachedRoles();
    final index = currentRoles.indexWhere((r) => r.id == id);
    final updatedRole = RoleModel(
      id: id,
      name: name.trim(),
      permissionIds: permissionIds ??
          (index != -1 ? currentRoles[index].permissionIds : const []),
      updatedAt: DateTime.now().toIso8601String(),
    );

    if (index != -1) {
      currentRoles[index] = updatedRole;
    } else {
      currentRoles.add(updatedRole);
    }
    await _cacheRoles(currentRoles);

    return updatedRole;
  }

  @override
  Future<bool> deleteRole(int id) async {
    final uri = Uri.parse('$_baseUrl/api/Roles/$id');
    try {
      final headers = await _headers();
      await _client.delete(uri, headers: headers);
    } catch (_) {}

    final currentRoles = await _getCachedRoles();
    currentRoles.removeWhere((r) => r.id == id);
    await _cacheRoles(currentRoles);
    return true;
  }

  @override
  Future<List<PermissionModel>> getPermissions() async {
    final uri = Uri.parse('$_baseUrl/api/Permissions');
    try {
      final headers = await _headers();
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final perms = decoded
              .map((e) =>
                  PermissionModel.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
          return perms;
        }
      }
    } catch (_) {}

    return PermissionModel.defaultPermissions;
  }

  @override
  Future<bool> saveRolePermissions(int roleId, List<int> permissionIds) async {
    // Try posting to backend if RolePermissions endpoint is available
    try {
      final uri = Uri.parse('$_baseUrl/api/RolePermissions');
      final headers = await _headers();
      for (final pId in permissionIds) {
        try {
          await _client.post(
            uri,
            headers: headers,
            body: jsonEncode({'roleId': roleId, 'permissionId': pId}),
          );
        } catch (_) {}
      }
    } catch (_) {}

    // Persist mapping locally
    final prefs = await SharedPreferences.getInstance();
    final map = await _getRolePermissionsMap();
    map[roleId.toString()] = permissionIds;
    await prefs.setString(_rolePermissionsMapKey, jsonEncode(map));

    // Update in cached roles as well
    final cached = await _getCachedRoles();
    final idx = cached.indexWhere((r) => r.id == roleId);
    if (idx != -1) {
      cached[idx] = cached[idx].copyWith(permissionIds: permissionIds);
      await _cacheRoles(cached);
    }

    return true;
  }

  Future<Map<String, List<int>>> _getRolePermissionsMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rolePermissionsMapKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(
            k,
            (v as List).map((e) => int.parse(e.toString())).toList(),
          ));
    } catch (_) {
      return {};
    }
  }

  Future<List<RoleModel>> _getCachedRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedRolesKey);
    if (raw == null || raw.isEmpty) {
      return RoleModel.defaultRoles;
    }
    try {
      final decoded = jsonDecode(raw) as List;
      if (decoded.isEmpty) return RoleModel.defaultRoles;
      return decoded
          .map((e) => RoleModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return RoleModel.defaultRoles;
    }
  }

  Future<void> _cacheRoles(List<RoleModel> roles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cachedRolesKey,
      jsonEncode(roles.map((e) => e.toMap()).toList()),
    );
  }
}

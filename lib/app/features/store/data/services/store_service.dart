import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store_entity.dart';

class StoreService {
  static const String _storageKey = 'store_profile_info';
  static const String _legacyStorageKey = 'restaurant_profile_info';
  static const String _hasStoreKey = 'store_is_registered';
  static const String _legacyHasStoreKey = 'restaurant_is_registered';
  static const String _activeStoreIdKey = 'active_store_tenant_id';
  static const String _accessibleStoresKey = 'accessible_stores_cache';

  /// Returns whether a store has been registered.
  Future<bool> hasRegisteredStore([String? userIdOrEmail]) async {
    final prefs = await SharedPreferences.getInstance();
    if (userIdOrEmail != null && userIdOrEmail.isNotEmpty) {
      final userKey = '${_hasStoreKey}_${userIdOrEmail.toLowerCase().trim()}';
      if (prefs.containsKey(userKey)) {
        return prefs.getBool(userKey) ?? false;
      }
      final legacyUserKey =
          '${_legacyHasStoreKey}_${userIdOrEmail.toLowerCase().trim()}';
      if (prefs.containsKey(legacyUserKey)) {
        return prefs.getBool(legacyUserKey) ?? false;
      }
    }
    return prefs.getBool(_hasStoreKey) ??
        prefs.getBool(_legacyHasStoreKey) ??
        false;
  }

  /// Sets whether a store is registered.
  Future<void> setHasRegisteredStore(
    bool value, [
    String? userIdOrEmail,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasStoreKey, value);
    await prefs.setBool(_legacyHasStoreKey, value);
    if (userIdOrEmail != null && userIdOrEmail.isNotEmpty) {
      final userKey = '${_hasStoreKey}_${userIdOrEmail.toLowerCase().trim()}';
      final legacyUserKey =
          '${_legacyHasStoreKey}_${userIdOrEmail.toLowerCase().trim()}';
      await prefs.setBool(userKey, value);
      await prefs.setBool(legacyUserKey, value);
    }
  }

  /// Active Tenant Storage: Retrieves currently active tenant store ID
  Future<int?> getActiveStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeStoreIdKey);
  }

  /// Active Tenant Storage: Persists active tenant store ID
  Future<void> setActiveStoreId(int storeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeStoreIdKey, storeId);
  }

  /// Clears active store ID
  Future<void> clearActiveStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeStoreIdKey);
  }

  /// Caches list of accessible stores for offline/immediate UI rendering
  Future<void> cacheAccessibleStores(List<StoreEntity> stores) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = stores.map((s) => s.toMap()).toList();
      await prefs.setString(_accessibleStoresKey, json.encode(listJson));
    } catch (_) {}
  }

  /// Retrieves cached list of accessible stores
  Future<List<StoreEntity>> getCachedAccessibleStores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_accessibleStoresKey);
      if (str == null || str.isEmpty) return [];
      final list = json.decode(str) as List;
      return list
          .map((item) => StoreEntity.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Default entity preset for this service
  StoreEntity get defaultEntity => StoreEntity.defaultStore();

  /// Fetches saved store information or seeds default if empty
  Future<StoreEntity> getStoreInfo() async {
    final prefs = await SharedPreferences.getInstance();
    var jsonString = prefs.getString(_storageKey);
    jsonString ??= prefs.getString(_legacyStorageKey);

    if (jsonString == null || jsonString.isEmpty) {
      final defaultInfo = defaultEntity;
      await prefs.setString(_storageKey, json.encode(defaultInfo.toMap()));
      return defaultInfo;
    }

    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      return StoreEntity.fromMap(data);
    } catch (_) {
      final fallback = defaultEntity;
      await prefs.setString(_storageKey, json.encode(fallback.toMap()));
      return fallback;
    }
  }

  /// Updates and persists the store profile
  Future<bool> updateStoreInfo(StoreEntity info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updated = info.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );
      final jsonStr = json.encode(updated.toMap());
      await prefs.setString(_storageKey, jsonStr);
      await prefs.setString(_legacyStorageKey, jsonStr);
      if (int.tryParse(info.id) != null) {
        await setActiveStoreId(int.parse(info.id));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Resets store information to default preset
  Future<StoreEntity> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultInfo = defaultEntity;
    final jsonStr = json.encode(defaultInfo.toMap());
    await prefs.setString(_storageKey, jsonStr);
    await prefs.setString(_legacyStorageKey, jsonStr);
    return defaultInfo;
  }

  // --- Legacy Compatibility Methods ---
  Future<bool> hasRegisteredRestaurant([String? userIdOrEmail]) =>
      hasRegisteredStore(userIdOrEmail);

  Future<void> setHasRegisteredRestaurant(
    bool value, [
    String? userIdOrEmail,
  ]) => setHasRegisteredStore(value, userIdOrEmail);

  Future<StoreEntity> getRestaurantInfo() => getStoreInfo();

  Future<bool> updateRestaurantInfo(StoreEntity info) => updateStoreInfo(info);
}

/// Backward compatibility alias class
class RestaurantService extends StoreService {
  @override
  StoreEntity get defaultEntity => StoreEntity.defaultRestaurant();
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/app_config.dart';
import '../../../auth/data/datasources/auth_token_storage.dart';
import '../models/working_day_model.dart';

abstract class WorkingDaysService {
  Future<List<WorkingDayModel>> getWorkingDays({int? userId});
  Future<WorkingDayModel> createWorkingDay(WorkingDayModel workingDay);
  Future<bool> deleteWorkingDay(int id);
  Future<List<WorkingDayModel>> saveWorkingDaysForUser({
    required int userId,
    required List<WorkingDayModel> days,
  });
}

class ApiWorkingDaysService implements WorkingDaysService {
  final http.Client _client;
  final AuthTokenStorage _tokenStorage;
  final String? _baseUrlOverride;

  static const String _cachedPrefix = 'cached_working_days_user_';

  ApiWorkingDaysService({
    http.Client? client,
    required AuthTokenStorage tokenStorage,
    String? baseUrlOverride,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage,
        _baseUrlOverride = baseUrlOverride;

  String get _baseUrl =>
      (_baseUrlOverride ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.getAccessToken();
    final headers = <String, String>{
      'accept': '*/*',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  Future<List<WorkingDayModel>> getWorkingDays({int? userId}) async {
    final uri = Uri.parse('$_baseUrl/api/working-days');
    try {
      final headers = await _headers();
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          final allDays = decoded
              .map((e) => WorkingDayModel.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();

          if (userId != null) {
            final userDays = allDays.where((d) => d.userId == userId).toList();
            await _cacheDays(userId, userDays);
            return userDays;
          }
          return allDays;
        }
      }
    } catch (_) {}

    if (userId != null) {
      return _getCachedDays(userId);
    }
    return [];
  }

  @override
  Future<WorkingDayModel> createWorkingDay(WorkingDayModel workingDay) async {
    final uri = Uri.parse('$_baseUrl/api/working-days');
    try {
      final headers = await _headers();
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(workingDay.toMap()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return WorkingDayModel.fromMap(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {}

    // Fallback if offline
    return workingDay.copyWith(
      id: workingDay.id ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<bool> deleteWorkingDay(int id) async {
    final uri = Uri.parse('$_baseUrl/api/working-days/$id');
    try {
      final headers = await _headers();
      final response = await _client.delete(uri, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
    } catch (_) {}
    return true;
  }

  @override
  Future<List<WorkingDayModel>> saveWorkingDaysForUser({
    required int userId,
    required List<WorkingDayModel> days,
  }) async {
    final savedDays = <WorkingDayModel>[];

    // Post each day to backend
    for (final day in days) {
      try {
        final created = await createWorkingDay(day.copyWith(userId: userId));
        savedDays.add(created);
      } catch (_) {
        savedDays.add(day.copyWith(userId: userId));
      }
    }

    // Persist to local cache
    await _cacheDays(userId, savedDays);
    return savedDays;
  }

  Future<void> _cacheDays(int userId, List<WorkingDayModel> days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_cachedPrefix$userId',
      jsonEncode(days.map((e) => e.toMap()).toList()),
    );
  }

  Future<List<WorkingDayModel>> _getCachedDays(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cachedPrefix$userId');
    if (raw == null || raw.isEmpty) {
      // Default initial workdays: Sunday (0) to Thursday (4) from 08:00 to 17:00
      return [
        WorkingDayModel(userId: userId, day: 0, fromTime: '08:00:00', toTime: '17:00:00'),
        WorkingDayModel(userId: userId, day: 1, fromTime: '08:00:00', toTime: '17:00:00'),
        WorkingDayModel(userId: userId, day: 2, fromTime: '08:00:00', toTime: '17:00:00'),
        WorkingDayModel(userId: userId, day: 3, fromTime: '08:00:00', toTime: '17:00:00'),
        WorkingDayModel(userId: userId, day: 4, fromTime: '08:00:00', toTime: '17:00:00'),
      ];
    }
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => WorkingDayModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

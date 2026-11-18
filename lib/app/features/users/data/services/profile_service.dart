import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../config/app_config.dart';
import '../../../auth/data/datasources/auth_token_storage.dart';
import '../models/user_profile_dto.dart';

/// Contract for fetching and updating user profile data.
abstract class ProfileService {
  /// Fetches the profile of the currently authenticated user.
  Future<UserProfileDto> getProfile();

  /// Updates the profile data of the currently authenticated user.
  Future<UserProfileDto> updateProfile(UserProfileDto profile);

  /// Uploads an avatar image for the user profile using multipart/form-data.
  ///
  /// Returns the image URL if provided by the backend.
  Future<String?> uploadProfileImage({
    required List<int> fileBytes,
    required String fileName,
  });

  /// Changes the user's password.
  Future<void> changePassword({
    required String newPassword,
    required String confirmedPassword,
  });
}

/// Custom exception thrown when a profile API call fails.
class ProfileApiException implements Exception {
  final String message;
  final int? statusCode;

  const ProfileApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ProfileApiException: $message (code: $statusCode)';
}

/// Remote implementation of [ProfileService] communicating with the backend API.
class ApiProfileService implements ProfileService {
  final http.Client _client;
  final AuthTokenStorage _tokenStorage;
  final String? _baseUrlOverride;

  ApiProfileService({
    http.Client? client,
    required AuthTokenStorage tokenStorage,
    String? baseUrlOverride,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage,
        _baseUrlOverride = baseUrlOverride;

  String get _baseUrl => (_baseUrlOverride ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), '');

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
  Future<UserProfileDto> getProfile() async {
    final uri = Uri.parse('$_baseUrl/api/Profile');
    final headers = await _headers();

    try {
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return const UserProfileDto(fullName: '', email: '');
        }
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return UserProfileDto.fromMap(decoded);
        } else if (decoded is Map) {
          return UserProfileDto.fromMap(Map<String, dynamic>.from(decoded));
        }
        return const UserProfileDto(fullName: '', email: '');
      } else if (response.statusCode == 401) {
        throw const ProfileApiException('انتهت صلاحية الجلسة، يرجى إعادة تسجيل الدخول', 401);
      } else if (response.statusCode == 404) {
        throw const ProfileApiException('لم يتم العثور على الملف الشخصي', 404);
      } else {
        throw ProfileApiException(
          'فشل تحميل الملف الشخصي: ${response.statusCode} ${response.body}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw const ProfileApiException('تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت');
    } catch (e) {
      if (e is ProfileApiException) rethrow;
      throw ProfileApiException('حدث خطأ أثناء تحميل الملف الشخصي: $e');
    }
  }

  @override
  Future<UserProfileDto> updateProfile(UserProfileDto profile) async {
    final uri = Uri.parse('$_baseUrl/api/Profile');
    final headers = await _headers();
    final body = jsonEncode(profile.toMap());

    try {
      final response = await _client.put(
        uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          try {
            final dynamic decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic>) {
              return UserProfileDto.fromMap(decoded);
            } else if (decoded is Map) {
              return UserProfileDto.fromMap(Map<String, dynamic>.from(decoded));
            }
          } catch (_) {}
        }
        return profile;
      } else if (response.statusCode == 401) {
        throw const ProfileApiException('انتهت صلاحية الجلسة، يرجى إعادة تسجيل الدخول', 401);
      } else if (response.statusCode == 400) {
        String msg = 'بيانات غير صحيحة';
        try {
          final dynamic decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['title'] != null) {
            msg = decoded['title'].toString();
          } else if (decoded is Map && decoded['message'] != null) {
            msg = decoded['message'].toString();
          }
        } catch (_) {}
        throw ProfileApiException(msg, 400);
      } else {
        throw ProfileApiException(
          'فشل تحديث الملف الشخصي: ${response.statusCode} ${response.body}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw const ProfileApiException('تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت');
    } catch (e) {
      if (e is ProfileApiException) rethrow;
      throw ProfileApiException('حدث خطأ أثناء تحديث الملف الشخصي: $e');
    }
  }

  @override
  Future<String?> uploadProfileImage({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/Profile/image');
    final token = await _tokenStorage.getAccessToken();

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers['accept'] = '*/*';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'File',
        fileBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          try {
            final dynamic decoded = jsonDecode(response.body);
            if (decoded is Map) {
              return decoded['imageUrl']?.toString() ??
                  decoded['profilePicture']?.toString() ??
                  decoded['url']?.toString() ??
                  decoded['path']?.toString();
            } else if (decoded is String) {
              return decoded;
            }
          } catch (_) {
            return response.body.trim();
          }
        }
        return null;
      } else if (response.statusCode == 401) {
        throw const ProfileApiException('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً', 401);
      } else {
        throw ProfileApiException(
          'فشل رفع الصورة: ${response.statusCode} ${response.body}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw const ProfileApiException('تعذر الاتصال بالخادم أثناء رفع الصورة');
    } catch (e) {
      if (e is ProfileApiException) rethrow;
      throw ProfileApiException('حدث خطأ أثناء رفع صورة الملف الشخصي: $e');
    }
  }

  @override
  Future<void> changePassword({
    required String newPassword,
    required String confirmedPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/Profile/change-password');
    final headers = await _headers(isJson: true);
    final body = jsonEncode({
      'newPassword': newPassword,
      'confirmedPassword': confirmedPassword,
    });

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else if (response.statusCode == 401) {
        throw const ProfileApiException('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً', 401);
      } else if (response.statusCode == 400) {
        String msg = 'فشل تغيير كلمة المرور: تحقق من صحة المدخلات';
        try {
          final dynamic decoded = jsonDecode(response.body);
          if (decoded is Map) {
            if (decoded['message'] != null) {
              msg = decoded['message'].toString();
            } else if (decoded['title'] != null) {
              msg = decoded['title'].toString();
            } else if (decoded['errors'] != null) {
              final errors = decoded['errors'];
              if (errors is Map) {
                final messages = errors.values.expand((v) => v is List ? v : [v]).join(', ');
                if (messages.isNotEmpty) msg = messages;
              }
            }
          } else if (decoded is String) {
            msg = decoded;
          }
        } catch (_) {}
        throw ProfileApiException(msg, 400);
      } else {
        throw ProfileApiException(
          'فشل تغيير كلمة المرور: ${response.statusCode} ${response.body}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw const ProfileApiException('تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت');
    } catch (e) {
      if (e is ProfileApiException) rethrow;
      throw ProfileApiException('حدث خطأ أثناء تغيير كلمة المرور: $e');
    }
  }
}

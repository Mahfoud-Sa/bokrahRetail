import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_session_model.dart';

/// Contract for persistent authentication credentials and token storage.
abstract class AuthTokenStorage {
  Future<void> saveSession(AuthSessionModel session);
  Future<AuthSessionModel?> getSession();
  Future<String?> getAccessToken();
  Future<void> clearSession();
  Future<bool> hasValidSession();
}

/// SharedPreferences implementation of token storage.
/// In production, sensitive tokens may be stored in flutter_secure_storage.
class SharedPrefsAuthTokenStorage implements AuthTokenStorage {
  static const String _keySession = 'auth_user_session';
  final SharedPreferences _prefs;

  SharedPrefsAuthTokenStorage({required SharedPreferences prefs})
      : _prefs = prefs;

  @override
  Future<void> saveSession(AuthSessionModel session) async {
    await _prefs.setString(_keySession, session.toJson());
  }

  @override
  Future<AuthSessionModel?> getSession() async {
    final raw = _prefs.getString(_keySession);
    if (raw == null || raw.isEmpty) return null;
    try {
      final session = AuthSessionModel.fromJson(raw);
      if (session.isExpired) {
        await clearSession();
        return null;
      }
      return session;
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    final session = await getSession();
    return session?.accessToken;
  }

  @override
  Future<void> clearSession() async {
    await _prefs.remove(_keySession);
  }

  @override
  Future<bool> hasValidSession() async {
    final session = await getSession();
    return session != null && !session.isExpired;
  }
}

class InMemoryAuthTokenStorage implements AuthTokenStorage {
  AuthSessionModel? _session;

  InMemoryAuthTokenStorage([this._session]);

  @override
  Future<void> saveSession(AuthSessionModel session) async {
    _session = session;
  }

  @override
  Future<AuthSessionModel?> getSession() async {
    if (_session != null && _session!.isExpired) {
      _session = null;
    }
    return _session;
  }

  @override
  Future<String?> getAccessToken() async {
    final session = await getSession();
    return session?.accessToken;
  }

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<bool> hasValidSession() async {
    final session = await getSession();
    return session != null && !session.isExpired;
  }
}

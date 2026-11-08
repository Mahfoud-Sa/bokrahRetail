import 'package:shared_preferences/shared_preferences.dart';

abstract class UpdatePreferencesDatasource {
  Future<void> setSkippedVersion(String version);
  Future<String?> getSkippedVersion();
  Future<void> clearSkippedVersion();
}

class SharedPrefsUpdatePreferencesDatasource implements UpdatePreferencesDatasource {
  static const String _keySkippedVersion = 'auto_update_skipped_version';
  final SharedPreferences _prefs;

  SharedPrefsUpdatePreferencesDatasource({required SharedPreferences prefs})
      : _prefs = prefs;

  @override
  Future<void> setSkippedVersion(String version) async {
    await _prefs.setString(_keySkippedVersion, version);
  }

  @override
  Future<String?> getSkippedVersion() async {
    return _prefs.getString(_keySkippedVersion);
  }

  @override
  Future<void> clearSkippedVersion() async {
    await _prefs.remove(_keySkippedVersion);
  }
}

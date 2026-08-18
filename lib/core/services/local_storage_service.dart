import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight wrapper around SharedPreferences for non-sensitive data.
class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  String? getString(String key) => _prefs.getString(key);
  int? getInt(String key) => _prefs.getInt(key);
  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();
}

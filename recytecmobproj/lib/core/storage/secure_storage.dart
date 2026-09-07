import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _userKey = 'auth_user';
  static const _darkModeKey = 'recytech_dark_mode';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> saveUserJson(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<String?> readUserJson() async {
    return _storage.read(key: _userKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> clearAuthSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<void> saveDarkMode(bool enabled) async {
    await _storage.write(key: _darkModeKey, value: enabled.toString());
  }

  Future<bool?> readDarkMode() async {
    final value = await _storage.read(key: _darkModeKey);
    if (value == null) return null;
    return value == 'true';
  }
}

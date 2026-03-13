import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _themeKey = 'theme_mode';
  static const String _onboardingKey = 'onboarding_complete';

  // Token management
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // User ID management
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  // Theme management
  Future<void> saveThemeMode(String themeMode) async {
    await _storage.write(key: _themeKey, value: themeMode);
  }

  Future<String?> getThemeMode() async {
    return await _storage.read(key: _themeKey);
  }

  // Onboarding management
  Future<void> setOnboardingComplete(bool complete) async {
    await _storage.write(key: _onboardingKey, value: complete.toString());
  }

  Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: _onboardingKey);
    return value == 'true';
  }

  // Clear all data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

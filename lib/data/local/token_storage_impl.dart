import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'token_storage.dart';

/// Bearer token in the iOS Keychain / Android Keystore (MOBILE_API_VELORA.md
/// §1), so Face ID can guard it. A token saved in plain preferences by an
/// older build is moved across on first read. If secure storage is not
/// available (e.g. widget tests) preferences are used instead.
class TokenStorageImpl implements TokenStorage {
  TokenStorageImpl({FlutterSecureStorage? secure})
      : _secure = secure ?? const FlutterSecureStorage();

  static const _keyAuthToken = 'auth_token';

  final FlutterSecureStorage _secure;

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_keyAuthToken);
    try {
      if (legacy != null && legacy.isNotEmpty) {
        await _secure.write(key: _keyAuthToken, value: legacy);
        await prefs.remove(_keyAuthToken);
        return legacy;
      }
      return await _secure.read(key: _keyAuthToken);
    } catch (_) {
      return legacy;
    }
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      await _secure.write(key: _keyAuthToken, value: token);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAuthToken, token);
    }
  }

  @override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    try {
      await _secure.delete(key: _keyAuthToken);
    } catch (_) {}
  }
}

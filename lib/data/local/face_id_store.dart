import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Whether this phone uses Face ID to unlock the saved session
/// (MOBILE_API_VELORA.md §1). The session token itself lives in
/// [TokenStorage]; no password is ever stored.
class FaceIdStore {
  FaceIdStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _enabled = 'face_id.enabled';
  static const _name = 'face_id.name';
  static const _lockedToken = 'face_id.locked_token';

  Future<bool> isEnabled() async {
    try {
      // An earlier build of this screen saved a password here; never again.
      await _storage.delete(key: 'face_id.email');
      await _storage.delete(key: 'face_id.password');
      return await _storage.read(key: _enabled) == 'true';
    } catch (_) {
      return false;
    }
  }

  /// First name for "Welcome back, Michael".
  Future<String?> name() async {
    try {
      return await _storage.read(key: _name);
    } catch (_) {
      return null;
    }
  }

  Future<void> enable({String? name}) async {
    await _storage.write(key: _enabled, value: 'true');
    if (name != null && name.isNotEmpty) {
      await _storage.write(key: _name, value: name);
    }
  }

  Future<void> disable() async {
    try {
      await _storage.delete(key: _enabled);
      await _storage.delete(key: _name);
      await _storage.delete(key: _lockedToken);
    } catch (_) {}
  }

  /// Sign out with Face ID on locks the session instead of ending it: the
  /// bearer token is parked here until Face ID unlocks it (then
  /// `POST /refresh` rotates it).
  Future<void> lockToken(String token) =>
      _storage.write(key: _lockedToken, value: token);

  Future<String?> lockedToken() async {
    try {
      final token = await _storage.read(key: _lockedToken);
      return token == null || token.isEmpty ? null : token;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLockedToken() async {
    try {
      await _storage.delete(key: _lockedToken);
    } catch (_) {}
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import 'remember_me_storage.dart';

class RememberMeStorageImpl implements RememberMeStorage {
  static const _keyEnabled = 'remember_me_enabled';
  static const _keyEmail = 'remember_me_email';
  static const _keyPassword = 'remember_me_password';

  @override
  Future<RememberMeCredentials> load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? false;

    if (!enabled) {
      return const RememberMeCredentials();
    }

    return RememberMeCredentials(
      enabled: true,
      email: prefs.getString(_keyEmail),
      password: prefs.getString(_keyPassword),
    );
  }

  @override
  Future<void> save({
    required bool enabled,
    String? email,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!enabled) {
      await prefs.remove(_keyEnabled);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyPassword);
      return;
    }

    await prefs.setBool(_keyEnabled, true);
    await prefs.setString(_keyEmail, email?.trim() ?? '');
    await prefs.setString(_keyPassword, password ?? '');
  }
}

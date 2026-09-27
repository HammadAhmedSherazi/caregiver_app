import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_config.dart';

/// Language sent as `Accept-Language` on every request (`en` or `ar`).
///
/// The server localizes every `*_label`, message and push into it. It is
/// updated from `settings.language` (`GET /me`, `PUT /me/settings`) once
/// those planned endpoints are live; until then it stays `en`.
class LanguageStore {
  static const _key = 'app_language';

  final ValueNotifier<String> language = ValueNotifier('en');

  String get current => language.value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && ApiConfig.supportedLanguages.contains(saved)) {
      language.value = saved;
    }
  }

  Future<void> set(String code) async {
    if (!ApiConfig.supportedLanguages.contains(code)) return;
    language.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}

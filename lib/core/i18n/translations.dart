import 'dart:convert';

import 'package:flutter/services.dart';

import '../network/api_config.dart';

/// UI copy loaded from `assets/i18n/<language>.json`.
///
/// Keys are dotted paths (`login.signIn`). A key missing from the chosen
/// language falls back to English, then to the key itself. `{name}`
/// placeholders are filled from [args].
class Translations {
  static const fallbackLanguage = 'en';

  final Map<String, Map<String, dynamic>> _byLanguage = {};

  Future<void> load({AssetBundle? bundle}) async {
    final source = bundle ?? rootBundle;
    for (final code in ApiConfig.supportedLanguages) {
      final raw = await source.loadString('assets/i18n/$code.json');
      _byLanguage[code] = jsonDecode(raw) as Map<String, dynamic>;
    }
  }

  String text(
    String language,
    String key, [
    Map<String, String> args = const {},
  ]) {
    var value = _lookup(language, key) ??
        _lookup(fallbackLanguage, key) ??
        key;
    args.forEach((name, arg) => value = value.replaceAll('{$name}', arg));
    return value;
  }

  /// App-wide copy keyed by the English text itself (`ui` section of
  /// `ar.json`). English, or a missing entry, returns [english] unchanged.
  /// `{0}`, `{1}`… are filled from [args].
  String ui(String language, String english, [List<Object?> args = const []]) {
    var value = english;
    if (language != fallbackLanguage) {
      final table = _byLanguage[language]?['ui'];
      if (table is Map<String, dynamic>) {
        final hit = table[english];
        if (hit is String && hit.isNotEmpty) value = hit;
      }
    }
    for (var i = 0; i < args.length; i++) {
      value = value.replaceAll('{$i}', '${args[i] ?? ''}');
    }
    return value;
  }

  String? _lookup(String language, String key) {
    Object? node = _byLanguage[language];
    for (final part in key.split('.')) {
      if (node is! Map<String, dynamic>) return null;
      node = node[part];
    }
    return node is String ? node : null;
  }
}

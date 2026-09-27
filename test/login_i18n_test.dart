import 'dart:convert';
import 'dart:io';

import 'package:caregiver_app/core/i18n/translations.dart';
import 'package:caregiver_app/presentation/auth/view/login_strings.dart';
import 'package:flutter_test/flutter_test.dart';

Set<String> _keys(Map<String, dynamic> map, [String prefix = '']) => {
      for (final e in map.entries)
        if (e.value is Map<String, dynamic>)
          ..._keys(e.value as Map<String, dynamic>, '$prefix${e.key}.')
        else
          '$prefix${e.key}',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = Translations();

  setUpAll(translations.load);

  test('en.json and ar.json define the same keys', () {
    Map<String, dynamic> read(String code) =>
        jsonDecode(File('assets/i18n/$code.json').readAsStringSync())
            as Map<String, dynamic>;
    // `ui` is Arabic-only: its keys are the English text itself.
    final ar = read('ar')..remove('ui');
    expect(_keys(ar), _keys(read('en')));
  });

  test('sign-in subtitle and text follow the language', () {
    final en = LoginStrings(translations, 'en');
    final ar = LoginStrings(translations, 'ar');

    expect(en.tagline, 'Supportive Solutions Home Care');
    expect(ar.tagline, 'لمقدّمي الرعاية في Supportive Solutions Home Care');
    expect(en.signIn, 'Sign in');
    expect(ar.signIn, 'تسجيل الدخول');
    expect(ar.isArabic, isTrue);
  });

  test('placeholders are filled and missing keys fall back to English', () {
    expect(translations.text('en', 'login.faceSignIn', {'method': 'Face ID'}),
        'Sign in with Face ID');
    expect(translations.text('ar', 'login.faceSignIn', {'method': 'Face ID'}),
        'الدخول بـ Face ID');
    expect(translations.text('fr', 'login.signIn'), 'Sign in');
    expect(translations.text('en', 'login.nope'), 'login.nope');
  });
}

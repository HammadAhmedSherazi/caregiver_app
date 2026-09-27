import '../../data/local/language_store.dart';
import '../di/service_locator.dart';
import 'translations.dart';

/// Translates app copy into the language chosen on the sign-in screen or in
/// Profile. [english] is both the key and the fallback; `{0}`, `{1}`… are
/// filled from [args]:
///
/// ```dart
/// Text(tr('Report a change'))
/// Text(tr('Signed {0}', [VeloraFormat.monthDay(date)]))
/// ```
///
/// Arabic lives in the `ui` section of `assets/i18n/ar.json`. Screens are
/// rebuilt when the language changes (see `App`), so plain calls are enough.
String tr(String english, [List<Object?> args = const []]) {
  if (!sl.isRegistered<Translations>() || !sl.isRegistered<LanguageStore>()) {
    var value = english;
    for (var i = 0; i < args.length; i++) {
      value = value.replaceAll('{$i}', '${args[i] ?? ''}');
    }
    return value;
  }
  return sl<Translations>().ui(sl<LanguageStore>().current, english, args);
}

/// True while the app is in Arabic.
bool get isArabic =>
    sl.isRegistered<LanguageStore>() && sl<LanguageStore>().current == 'ar';

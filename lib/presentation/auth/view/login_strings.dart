import '../../../core/di/service_locator.dart';
import '../../../core/i18n/translations.dart';

/// Sign-in copy, read from the `login` section of `assets/i18n/en.json`
/// and `assets/i18n/ar.json`.
class LoginStrings {
  const LoginStrings(this._translations, this.languageCode);

  factory LoginStrings.of(String languageCode) =>
      LoginStrings(sl<Translations>(), languageCode);

  final Translations _translations;
  final String languageCode;

  bool get isArabic => languageCode == 'ar';

  String _t(String key, [String? method]) => _translations.text(
        languageCode,
        'login.$key',
        method == null ? const {} : {'method': method},
      );

  String get tagline => _t('tagline');
  String get welcome => _t('welcome');
  String get email => _t('email');
  String get password => _t('password');
  String get showPassword => _t('showPassword');
  String get hidePassword => _t('hidePassword');
  String get rememberMe => _t('rememberMe');
  String get signIn => _t('signIn');
  String get emailRequired => _t('emailRequired');
  String get emailInvalid => _t('emailInvalid');
  String get passwordRequired => _t('passwordRequired');
  String get useEmail => _t('useEmail');
  String get scanning => _t('scanning');
  String get cancel => _t('cancel');
  String get failSub => _t('failSub');
  String get lockedSub => _t('lockedSub');
  String get languageLabel => _t('language');
  String get usePhone => _t('usePhone');
  String get signPhone => _t('signPhone');
  String get inviteLink => _t('inviteLink');
  String get emailLink => _t('emailLink');
  String get emailTitle => _t('emailTitle');
  String get back => _t('back');
  String get delete => _t('delete');
  String get phoneTitle => _t('phoneTitle');
  String get send => _t('send');
  String get codeTitle => _t('codeTitle');
  String get resend => _t('resend');
  String get sending => _t('sending');
  String get verifying => _t('verifying');
  String get signingIn => _t('signingIn');
  String get inviteTitle => _t('inviteTitle');
  String get inviteSub => _t('inviteSub');
  String get inviteLabel => _t('inviteLabel');
  String get checkInvite => _t('checkInvite');
  String get checking => _t('checking');
  String get invitedBy => _t('invitedBy');
  String get you => _t('you');
  String get client => _t('client');
  String get looksRight => _t('looksRight');
  String get notMe => _t('notMe');
  String get phoneNotLive => _t('phoneNotLive');
  String get genericError => _t('genericError');

  String get trouble => _t('trouble');
  String get emailSignIn => _t('emailSignIn');
  String faceOffTitle(String method) => _t('faceOffTitle', method);
  String faceOffSubFor(String method) => _t('faceOffSub', method);
  String faceMissingTitle(String method) => _t('faceMissingTitle', method);
  String get faceMissingSub => _t('faceMissingSub');
  String faceSignedOutTitle(String method) => _t('faceSignedOutTitle', method);
  String faceSignedOutSub(String method) => _t('faceSignedOutSub', method);
  String get notNow => _t('notNow');
  String get doneSub => _t('doneSub');
  String get go => _t('go');
  String setupTitle(String method) => _t('setupTitle', method);
  String setupSub(String method) => _t('setupSub', method);
  String turnOn(String method) => _t('turnOn', method);

  String welcomeFor(String? name) => _named('welcome', name);
  String doneTitle(String? name) => _named('doneTitle', name);

  String _named(String key, String? name) => name == null || name.isEmpty
      ? _t(key)
      : _translations.text(languageCode, 'login.${key}Name', {'name': name});

  String codeSub(String phone) =>
      _translations.text(languageCode, 'login.codeSub', {'phone': phone});
  String resendIn(String time) =>
      _translations.text(languageCode, 'login.resendIn', {'time': time});

  String faceSignIn(String method) => _t('faceSignIn', method);
  String faceReason(String method) => _t('faceReason', method);
  String faceLater(String method) => _t('faceLater', method);
  String failTitle(String method) => _t('failTitle', method);
  String lockedTitle(String method) => _t('lockedTitle', method);
  String tryAgain(String method) => _t('tryAgain', method);

  String greeting([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return _t('goodMorning');
    if (hour < 17) return _t('goodAfternoon');
    return _t('goodEvening');
  }
}

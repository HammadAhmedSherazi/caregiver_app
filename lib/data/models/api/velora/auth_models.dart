import 'package:equatable/equatable.dart';

import '../../user_model.dart';
import 'json.dart';

/// Response of `POST /auth/phone/send-code` and `POST /auth/invite/confirm`
/// (§1). Identical whether or not the number is registered.
class PhoneCodeSentModel extends Equatable {
  const PhoneCodeSentModel({
    required this.message,
    required this.phoneMasked,
    required this.expiresIn,
    required this.resendIn,
  });

  final String message;
  final String phoneMasked;

  /// Code lifetime (contract: 300 s).
  final Duration expiresIn;

  /// Drives the "Resend code" countdown (contract: 30 s).
  final Duration resendIn;

  factory PhoneCodeSentModel.fromJson(Json json) {
    final data = jsonMap(json['data']) ?? const {};
    return PhoneCodeSentModel(
      message: strOr(json['message']),
      phoneMasked: strOr(data['phone_masked']),
      expiresIn: Duration(seconds: intOrNull(data['expires_in']) ?? 300),
      resendIn: Duration(seconds: intOrNull(data['resend_in']) ?? 30),
    );
  }

  @override
  List<Object?> get props => [message, phoneMasked, expiresIn, resendIn];
}

/// Response of `POST /auth/phone/verify` — same shape as `POST /login`.
class PhoneVerifyResultModel extends Equatable {
  const PhoneVerifyResultModel({
    required this.token,
    required this.user,
    required this.firstSignIn,
  });

  final String token;
  final UserModel user;

  /// `true` → offer "Turn on Face ID?".
  final bool firstSignIn;

  static PhoneVerifyResultModel? maybeFromJson(Json json) {
    final token = str(json['token']);
    final user = jsonMap(json['user']);
    if (token == null || user == null) return null;
    return PhoneVerifyResultModel(
      token: token,
      user: UserModel.fromJson(user),
      firstSignIn: boolOrNull(json['first_sign_in']) ?? false,
    );
  }

  @override
  List<Object?> get props => [token, user, firstSignIn];
}

/// `POST /auth/invite/check` → "Is this you?".
class InviteDetailsModel extends Equatable {
  const InviteDetailsModel({
    required this.agencyName,
    required this.caregiverName,
    required this.clientName,
    this.expiresAt,
  });

  final String agencyName;
  final String caregiverName;
  final String clientName;
  final DateTime? expiresAt;

  factory InviteDetailsModel.fromJson(Json json) {
    final data = jsonMap(json['data']) ?? json;
    return InviteDetailsModel(
      agencyName: strOr(data['agency_name']),
      caregiverName: strOr(data['caregiver_name']),
      clientName: strOr(data['client_name']),
      expiresAt: dateOrNull(data['expires_at']),
    );
  }

  @override
  List<Object?> get props => [agencyName, caregiverName, clientName, expiresAt];
}

/// Request-side helpers for §1.
class PhoneAuthRules {
  PhoneAuthRules._();

  /// Normalizes any US format to `+1XXXXXXXXXX` (the server also normalizes;
  /// this only catches obviously incomplete numbers before sending).
  static String? normalizeUsPhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) {
      return digits.length >= 11 ? digits : null;
    }
    final plain = digits.replaceAll('+', '');
    if (plain.length == 10) return '+1$plain';
    if (plain.length == 11 && plain.startsWith('1')) return '+$plain';
    return null;
  }

  static bool isValidCode(String code) => RegExp(r'^\d{6}$').hasMatch(code.trim());

  /// Case, spaces and dashes are forgiven by the server; only reject empty.
  static String normalizeInvite(String code) => code.trim();
}

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_exception.dart';
import '../api/caregiver_api.dart';
import '../local/session_storage.dart';
import '../local/token_storage.dart';
import '../models/user_model.dart';
import '../api/velora_api.dart';
import '../models/api/velora/velora_models.dart';

abstract class AuthRepository {
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted();

  Future<UserModel?> getCurrentUser();
  Future<bool> hasStoredSession();
  /// [device] also registers this phone for push in the same call.
  Future<UserModel> login({
    required String email,
    required String password,
    DeviceRegistrationRequest? device,
  });
  Future<void> signup({
    required String name,
    required String email,
    required String password,
  });
  Future<void> resendVerificationEmail({required String email});
  Future<void> submitActivationCode({
    required String email,
    required String code,
  });
  Future<void> completeRegistration({
    required String email,
    required String fullName,
    required String ssnLast4,
    required String dateOfBirth,
    required String phoneNumber,
  });
  Future<void> acceptPrivacyTerms({required String email});
  Future<void> forgotPassword({required String email});
  /// [fcmToken] stops pushes for this account on this phone.
  Future<void> logout({String? fcmToken});
  Future<void> clearLocalSession();

  /// `DELETE /account` — permanent. On success the local session is cleared.
  /// Returns the server's confirmation message.
  Future<String> deleteAccount({required String password});
  Future<bool> refreshSession();

  // 🚧 PLANNED — NOT LIVE (MOBILE_API_VELORA.md §1). Email + password keeps
  // working alongside phone sign-in (Open decision D5).

  /// `POST /auth/phone/send-code`.
  Future<PhoneCodeSentModel> sendPhoneCode({required String phone});

  /// `POST /auth/phone/verify` — signs in and stores the session like [login].
  Future<PhoneVerifyResultModel> verifyPhoneCode({
    required String phone,
    required String code,
    required String deviceName,
  });

  /// `POST /auth/invite/check`.
  Future<InviteDetailsModel> checkInvite({required String code});

  /// `POST /auth/invite/confirm` — then [verifyPhoneCode].
  Future<PhoneCodeSentModel> confirmInvite({required String code, required String phone});
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._api,
    required this._tokenStorage,
    required this._sessionStorage,
    required this._velora,
  });

  final VeloraApi _velora;

  static const _keyOnboardingCompleted = 'onboarding_completed';

  final CaregiverApi _api;
  final TokenStorage _tokenStorage;
  final SessionStorage _sessionStorage;

  UserModel? _cachedUser;

  @override
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  @override
  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);
  }

  @override
  Future<bool> hasStoredSession() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    _cachedUser ??= await _sessionStorage.loadUser();

    try {
      final profile = await _api.getMe();
      // /me returns caregiver profile id, which can differ from the
      // Sanctum auth user id used by private-user.{id} broadcasting.
      // Never replace a known auth user id with the profile id.
      final authUserId = _cachedUser?.id;
      final resolvedId =
          (authUserId != null && authUserId.isNotEmpty && authUserId != '0')
              ? authUserId
              : profile.id.toString();

      _cachedUser = UserModel(
        id: resolvedId,
        name: profile.name,
        email: profile.email,
        avatarUrl: profile.avatarUrl,
      );
      await _sessionStorage.saveUser(_cachedUser!);
      return _cachedUser;
    } on UnauthorizedException {
      await clearLocalSession();
      return null;
    } catch (_) {
      if (_cachedUser != null) {
        return _cachedUser;
      }

      return const UserModel(
        id: '0',
        name: 'Caregiver',
        email: '',
      );
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
    DeviceRegistrationRequest? device,
  }) async {
    try {
      final result = await _api.login(
        email: email,
        password: password,
        device: device,
      );
      _cachedUser = result.user;
      await _sessionStorage.saveUser(result.user);
      return result.user;
    } on ApiException catch (error) {
      throw AuthException(error.message);
    }
  }

  @override
  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    throw AuthException('Account signup is not available in the mobile app.');
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    throw AuthException('Email verification is not available in the mobile app.');
  }

  @override
  Future<void> submitActivationCode({
    required String email,
    required String code,
  }) async {
    throw AuthException('Activation codes are not available in the mobile app.');
  }

  @override
  Future<void> completeRegistration({
    required String email,
    required String fullName,
    required String ssnLast4,
    required String dateOfBirth,
    required String phoneNumber,
  }) async {
    throw AuthException('Registration is not available in the mobile app.');
  }

  @override
  Future<void> acceptPrivacyTerms({required String email}) async {
    throw AuthException('Registration is not available in the mobile app.');
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    throw AuthException('Password reset is not available in the mobile app.');
  }

  @override
  Future<void> logout({String? fcmToken}) async {
    try {
      await _api.logout(fcmToken: fcmToken);
    } finally {
      await clearLocalSession();
    }
  }

  @override
  Future<String> deleteAccount({required String password}) async {
    final message = await _velora.deleteAccount(password: password);
    await clearLocalSession();
    return message;
  }

  @override
  Future<void> clearLocalSession() async {
    _cachedUser = null;
    await _sessionStorage.clearUser();
    await _tokenStorage.clearToken();
  }

  @override
  Future<bool> refreshSession() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final result = await _api.refresh();
      _cachedUser = result.user;
      await _sessionStorage.saveUser(result.user);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<PhoneCodeSentModel> sendPhoneCode({required String phone}) {
    final normalized = PhoneAuthRules.normalizeUsPhone(phone);
    if (normalized == null) {
      throw RequestValidationException({
        'phone': ['Enter a 10-digit mobile number.'],
      });
    }
    return _velora.sendPhoneCode(phone: normalized);
  }

  @override
  Future<PhoneVerifyResultModel> verifyPhoneCode({
    required String phone,
    required String code,
    required String deviceName,
  }) async {
    final normalized = PhoneAuthRules.normalizeUsPhone(phone);
    if (normalized == null || !PhoneAuthRules.isValidCode(code)) {
      throw RequestValidationException({
        if (normalized == null) 'phone': ['Enter a 10-digit mobile number.'],
        if (!PhoneAuthRules.isValidCode(code)) 'code': ['Enter the 6-digit code.'],
      });
    }
    final result = await _velora.verifyPhoneCode(
      phone: normalized,
      code: code.trim(),
      deviceName: deviceName,
    );
    _cachedUser = result.user;
    await _sessionStorage.saveUser(result.user);
    return result;
  }

  @override
  Future<InviteDetailsModel> checkInvite({required String code}) {
    final normalized = PhoneAuthRules.normalizeInvite(code);
    if (normalized.isEmpty) {
      throw RequestValidationException({
        'code': ['Enter your invite code.'],
      });
    }
    return _velora.checkInvite(code: normalized);
  }

  @override
  Future<PhoneCodeSentModel> confirmInvite({required String code, required String phone}) {
    final normalized = PhoneAuthRules.normalizeUsPhone(phone);
    if (normalized == null) {
      throw RequestValidationException({
        'phone': ['Enter a 10-digit mobile number.'],
      });
    }
    return _velora.confirmInvite(code: PhoneAuthRules.normalizeInvite(code), phone: normalized);
  }
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_exception.dart';
import '../api/caregiver_api.dart';
import '../local/session_storage.dart';
import '../local/token_storage.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted();

  Future<UserModel?> getCurrentUser();
  Future<bool> hasStoredSession();
  Future<UserModel> login({required String email, required String password});
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
  Future<void> logout();
  Future<void> clearLocalSession();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required CaregiverApi api,
    required TokenStorage tokenStorage,
    required SessionStorage sessionStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage,
        _sessionStorage = sessionStorage;

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
      _cachedUser = UserModel(
        id: profile.id.toString(),
        name: profile.name,
        email: profile.email,
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
  }) async {
    try {
      final result = await _api.login(email: email, password: password);
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
  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await clearLocalSession();
    }
  }

  @override
  Future<void> clearLocalSession() async {
    _cachedUser = null;
    await _sessionStorage.clearUser();
    await _tokenStorage.clearToken();
  }
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

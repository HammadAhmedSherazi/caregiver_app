import 'package:flutter/foundation.dart';

import '../../../core/base/base_cubit.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/push/push_notification_handler.dart';
import '../../../core/network/chat_realtime_service.dart';
import '../../../data/local/face_id_store.dart';
import '../../../data/local/remember_me_storage.dart';
import '../../../data/local/token_storage.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import 'auth_state.dart';
import '../../../core/i18n/tr.dart';

class AuthCubit extends BaseCubit<AuthState> {
  AuthCubit({
    required this.repository,
    required this.rememberMeStorage,
  }) : super(const AuthState());

  final AuthRepository repository;
  final RememberMeStorage rememberMeStorage;

  Future<void> initialize() async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final hasSession = await repository.hasStoredSession();
      final faceStore = sl<FaceIdStore>();
      final canUnlock =
          hasSession || await faceStore.lockedToken() != null;
      if (canUnlock && await faceStore.isEnabled()) {
        // Face ID guards the saved session (MOBILE_API_VELORA.md §1): stay on
        // the sign-in screen until [unlockWithFaceId].
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            faceLocked: true,
            clearError: true,
          ),
        );
        return;
      }

      if (hasSession) {
        // Refresh restores the authenticatable user id (needed for Pusher
        // private-user.{id}). Local session may previously have stored /me
        // caregiver profile id by mistake.
        await repository.refreshSession();
        final user = await repository.getCurrentUser();
        if (user != null && await repository.hasStoredSession()) {
          emit(
            state.copyWith(
              status: AuthStatus.authenticated,
              user: user,
              clearError: true,
            ),
          );
          return;
        }
      }
    } catch (error, stackTrace) {
      logError('Failed to initialize auth', error: error, stackTrace: stackTrace);
    }

    emit(state.copyWith(status: AuthStatus.unauthenticated, clearError: true));
  }

  /// After a successful Face ID check: rotate the saved token with
  /// `POST /refresh` and hold the user for "You're in" ([finishSignIn]).
  Future<UserModel?> unlockWithFaceId() async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final faceStore = sl<FaceIdStore>();
    try {
      // After a Face ID sign-out the token is parked in the Face ID slot.
      final parked = await faceStore.lockedToken();
      if (parked != null && !await repository.hasStoredSession()) {
        await sl<TokenStorage>().saveToken(parked);
      }
      await faceStore.clearLockedToken();

      final refreshed = await repository.refreshSession();
      final user = refreshed ? await repository.getCurrentUser() : null;
      if (user != null && await repository.hasStoredSession()) {
        _pendingUser = user;
        emit(state.copyWith(isSubmitting: false));
        return user;
      }
    } catch (error, stackTrace) {
      logError('Face ID unlock failed', error: error, stackTrace: stackTrace);
    }
    await repository.clearLocalSession();
    emit(
      state.copyWith(
        isSubmitting: false,
        faceLocked: false,
        errorMessage: tr('Your session has ended. Please sign in again.'),
      ),
    );
    return null;
  }

  /// Records Face ID on/off on this phone and, once the planned
  /// `PUT /me/settings` is live, on the caregiver for support.
  Future<void> setFaceIdEnabled(bool enabled, {String? name}) async {
    final store = sl<FaceIdStore>();
    enabled ? await store.enable(name: name) : await store.disable();
    try {
      await sl<ProfileRepository>()
          .updateSettings(CaregiverSettingsModel(faceIdEnabled: enabled));
    } catch (_) {
      // Planned endpoint (ApiNotLiveException) or offline: the phone's own
      // setting is what gates Face ID, so this is best effort.
    }
  }

  // Phone sign-in (planned API, D5). These throw ApiException subclasses —
  // including ApiNotLiveException while VELORA_API is off — so the sign-in
  // screen can show the right message on the step the caregiver is on.

  Future<PhoneCodeSentModel> sendPhoneCode(String phone) =>
      repository.sendPhoneCode(phone: phone);

  Future<InviteDetailsModel> checkInvite(String code) =>
      repository.checkInvite(code: code);

  Future<PhoneCodeSentModel> confirmInvite({
    required String code,
    required String phone,
  }) =>
      repository.confirmInvite(code: code, phone: phone);

  /// Verifies the texted code and signs in, held for [finishSignIn].
  /// Returns `true` on the first sign-in from this phone.
  Future<bool> verifyPhoneCode({
    required String phone,
    required String code,
  }) async {
    final result = await repository.verifyPhoneCode(
      phone: phone,
      code: code,
      deviceName: defaultTargetPlatform == TargetPlatform.iOS
          ? 'VELORA iPhone'
          : 'VELORA Android',
    );
    await repository.setOnboardingCompleted();
    _pendingUser = result.user;
    return result.firstSignIn;
  }

  Future<RememberMeCredentials> getRememberMeCredentials() {
    return rememberMeStorage.load();
  }

  /// Signed in, but held on the sign-in screen for the "Turn on Face ID?"
  /// and "You're in" steps. [finishSignIn] lets the app through.
  UserModel? _pendingUser;

  /// Name of the caregiver held for [finishSignIn], if any.
  String? get pendingUserName => _pendingUser?.name;

  void finishSignIn() {
    final user = _pendingUser;
    _pendingUser = null;
    if (user == null) return;
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isSubmitting: false,
        faceLocked: false,
        clearError: true,
      ),
    );
  }

  /// Returns the user on success. With [deferSession] the app stays on the
  /// sign-in screen until [finishSignIn].
  Future<UserModel?> login({
    required String email,
    required String password,
    required bool rememberMe,
    bool deferSession = false,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final user = await repository.login(email: email, password: password);
      await sl<FaceIdStore>().clearLockedToken();
      await repository.setOnboardingCompleted();
      await rememberMeStorage.save(
        enabled: rememberMe,
        email: rememberMe ? email : null,
        password: rememberMe ? password : null,
      );
      if (deferSession) {
        _pendingUser = user;
        emit(state.copyWith(isSubmitting: false));
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            isSubmitting: false,
          ),
        );
      }
      return user;
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: error.message,
        ),
      );
    } catch (error, stackTrace) {
      logError('Login failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: tr('Sign in failed. Please try again.'),
        ),
      );
    }
    return null;
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await repository.signup(
        name: name,
        email: email,
        password: password,
      );
      emit(state.copyWith(isSubmitting: false));
      return true;
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: error.message,
        ),
      );
    } catch (error, stackTrace) {
      logError('Signup failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: tr('Account creation failed. Please try again.'),
        ),
      );
    }

    return false;
  }

  Future<bool> resendVerificationEmail({required String email}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await repository.resendVerificationEmail(email: email);
      emit(state.copyWith(isSubmitting: false));
      return true;
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: error.message,
        ),
      );
    } catch (error, stackTrace) {
      logError(
        'Resend verification email failed',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: tr('Unable to resend verification email. Please try again.'),
        ),
      );
    }

    return false;
  }

  Future<bool> submitActivationCode({
    required String email,
    required String code,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await repository.submitActivationCode(email: email, code: code);
      emit(state.copyWith(isSubmitting: false));
      return true;
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: error.message,
        ),
      );
    } catch (error, stackTrace) {
      logError('Activation code failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: tr('Unable to verify activation code. Please try again.'),
        ),
      );
    }

    return false;
  }

  Future<bool> completeRegistration({
    required String email,
    required String fullName,
    required String ssnLast4,
    required String dateOfBirth,
    required String phoneNumber,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await repository.completeRegistration(
        email: email,
        fullName: fullName,
        ssnLast4: ssnLast4,
        dateOfBirth: dateOfBirth,
        phoneNumber: phoneNumber,
      );
      emit(state.copyWith(isSubmitting: false));
      return true;
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: error.message,
        ),
      );
    } catch (error, stackTrace) {
      logError('Registration failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: tr('Registration failed. Please try again.'),
        ),
      );
    }

    return false;
  }

  Future<bool> acceptPrivacyTerms({required String email}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await repository.acceptPrivacyTerms(email: email);
      emit(state.copyWith(isSubmitting: false));
      return true;
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: error.message,
        ),
      );
    } catch (error, stackTrace) {
      logError('Accept terms failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: tr('Unable to complete registration. Please try again.'),
        ),
      );
    }

    return false;
  }

  Future<bool> forgotPassword({required String email}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await repository.forgotPassword(email: email);
      emit(state.copyWith(isSubmitting: false));
      return true;
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: error.message,
        ),
      );
    } catch (error, stackTrace) {
      logError('Forgot password failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: tr('Unable to send reset email. Please try again.'),
        ),
      );
    }

    return false;
  }

  void clearActionError() {
    emit(state.copyWith(clearError: true));
  }

  Future<void> handleSessionExpired() async {
    await sl<ChatRealtimeService>().disconnect();
    await repository.clearLocalSession();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isSubmitting: false,
        errorMessage: tr('Session expired. Please sign in again.'),
      ),
    );
  }

  /// With Face ID on, Sign out locks the session behind Face ID (the token
  /// is parked in the Keychain / Keystore and not revoked), so "Sign in with
  /// Face ID" works straight away — as in the design. With Face ID off it is
  /// a full sign-out (`POST /logout`).
  Future<void> logout() async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await sl<ChatRealtimeService>().disconnect();
      // Stop pushes to this phone (no-op while the planned API is off).
      await sl<PushNotificationHandler>().onSignOut();

      final faceStore = sl<FaceIdStore>();
      final token = await sl<TokenStorage>().getToken();
      final lockWithFace = await faceStore.isEnabled() &&
          token != null &&
          token.isNotEmpty;
      if (lockWithFace) {
        await faceStore.lockToken(token);
        await repository.clearLocalSession();
      } else {
        await repository.logout();
      }
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          isSubmitting: false,
          faceLocked: lockWithFace,
        ),
      );
    } catch (error, stackTrace) {
      logError('Logout failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: tr('Sign out failed. Please try again.'),
        ),
      );
    }
  }
}

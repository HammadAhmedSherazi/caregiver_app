import '../../../core/base/base_cubit.dart';
import '../../../data/local/remember_me_storage.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

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
      if (hasSession) {
        final user = await repository.getCurrentUser();
        if (user != null && await repository.hasStoredSession()) {
          await repository.setOnboardingCompleted();
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

      final onboardingCompleted = await repository.isOnboardingCompleted();
      if (!onboardingCompleted) {
        emit(state.copyWith(status: AuthStatus.onboarding, clearError: true));
        return;
      }

      emit(state.copyWith(status: AuthStatus.unauthenticated, clearError: true));
    } catch (error, stackTrace) {
      logError('Failed to initialize auth', error: error, stackTrace: stackTrace);

      final hasSession = await repository.hasStoredSession();
      if (hasSession) {
        final user = await repository.getCurrentUser();
        if (user != null && await repository.hasStoredSession()) {
          await repository.setOnboardingCompleted();
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

      final onboardingCompleted = await repository.isOnboardingCompleted();
      if (!onboardingCompleted) {
        emit(state.copyWith(status: AuthStatus.onboarding, clearError: true));
        return;
      }

      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Unable to load session. Please sign in.',
        ),
      );
    }
  }

  Future<void> completeOnboarding() async {
    try {
      await repository.setOnboardingCompleted();
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearError: true));
    } catch (error, stackTrace) {
      logError('Failed to complete onboarding', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  Future<RememberMeCredentials> getRememberMeCredentials() {
    return rememberMeStorage.load();
  }

  Future<void> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final user = await repository.login(email: email, password: password);
      await repository.setOnboardingCompleted();
      await rememberMeStorage.save(
        enabled: rememberMe,
        email: rememberMe ? email : null,
        password: rememberMe ? password : null,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isSubmitting: false,
        ),
      );
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
          errorMessage: 'Sign in failed. Please try again.',
        ),
      );
    }
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
          errorMessage: 'Account creation failed. Please try again.',
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
          errorMessage: 'Unable to resend verification email. Please try again.',
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
          errorMessage: 'Unable to verify activation code. Please try again.',
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
          errorMessage: 'Registration failed. Please try again.',
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
          errorMessage: 'Unable to complete registration. Please try again.',
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
          errorMessage: 'Unable to send reset email. Please try again.',
        ),
      );
    }

    return false;
  }

  void clearActionError() {
    emit(state.copyWith(clearError: true));
  }

  Future<void> handleSessionExpired() async {
    await repository.clearLocalSession();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isSubmitting: false,
        errorMessage: 'Session expired. Please sign in again.',
      ),
    );
  }

  Future<void> logout() async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await repository.logout();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          isSubmitting: false,
        ),
      );
    } catch (error, stackTrace) {
      logError('Logout failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Sign out failed. Please try again.',
        ),
      );
    }
  }
}

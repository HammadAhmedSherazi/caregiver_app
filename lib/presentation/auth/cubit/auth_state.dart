import 'package:equatable/equatable.dart';

import '../../../data/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  onboarding,
  unauthenticated,
  authenticated,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isSubmitting = false,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool isSubmitting;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? isSubmitting,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, isSubmitting];
}

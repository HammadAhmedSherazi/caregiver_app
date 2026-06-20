import '../models/user_model.dart';

abstract class AuthRepository {
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted();

  Future<UserModel?> getCurrentUser();
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  });
  Future<void> forgotPassword({required String email});
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  bool _onboardingCompleted = false;
  UserModel? _currentUser;

  static const _demoEmail = 'caregiver@example.com';
  static const _demoPassword = 'password123';

  @override
  Future<bool> isOnboardingCompleted() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _onboardingCompleted;
  }

  @override
  Future<void> setOnboardingCompleted() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _onboardingCompleted = true;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail == _demoEmail && password == _demoPassword) {
      _currentUser = const UserModel(
        id: 'user-1',
        name: 'Jane Caregiver',
        email: _demoEmail,
      );
      return _currentUser!;
    }

    throw AuthException('Invalid email or password');
  }

  @override
  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    if (password.length < 8) {
      throw AuthException('Password must be at least 8 characters');
    }

    _currentUser = UserModel(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim().toLowerCase(),
    );

    return _currentUser!;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail.contains('@')) {
      throw AuthException('Enter a valid email address');
    }
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

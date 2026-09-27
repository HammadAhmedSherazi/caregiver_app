import 'package:caregiver_app/core/di/service_locator.dart';
import 'package:caregiver_app/data/local/face_id_store.dart';
import 'package:caregiver_app/data/local/remember_me_storage.dart';
import 'package:caregiver_app/data/local/token_storage.dart';
import 'package:caregiver_app/data/models/user_model.dart';
import 'package:caregiver_app/data/repositories/auth_repository.dart';
import 'package:caregiver_app/presentation/auth/cubit/auth_cubit.dart';
import 'package:caregiver_app/presentation/auth/cubit/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _user = UserModel(id: '5', name: 'Michael Rodriguez', email: 'm@x.com');

class _Repo implements AuthRepository {
  _Repo({required this.session, required this.refreshOk});
  bool session;
  final bool refreshOk;
  int refreshCalls = 0;

  @override
  Future<bool> hasStoredSession() async {
    final token = await sl<TokenStorage>().getToken();
    return session || (token != null && token.isNotEmpty);
  }
  @override
  Future<bool> refreshSession() async {
    refreshCalls++;
    final token = await sl<TokenStorage>().getToken();
    if (token != null && token.isNotEmpty) session = true;
    return refreshOk && session;
  }
  @override
  Future<UserModel?> getCurrentUser() async => session ? _user : null;
  bool revoked = false;
  @override
  Future<void> clearLocalSession() async {
    session = false;
    await sl<TokenStorage>().clearToken();
  }
  @override
  Future<void> logout() async {
    revoked = true;
    await clearLocalSession();
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Store extends FaceIdStore {
  _Store(this.enabled);
  final bool enabled;
  String? parked;
  @override
  Future<bool> isEnabled() async => enabled;
  @override
  Future<void> lockToken(String token) async => parked = token;
  @override
  Future<String?> lockedToken() async => parked;
  @override
  Future<void> clearLockedToken() async => parked = null;
}

class _NoRemember implements RememberMeStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
  });

  _Store useFaceId(bool enabled) {
    final store = _Store(enabled);
    sl.unregister<FaceIdStore>();
    sl.registerSingleton<FaceIdStore>(store);
    return store;
  }

  test('saved session + Face ID on: stays on sign-in, locked, no refresh yet', () async {
    useFaceId(true);
    final repo = _Repo(session: true, refreshOk: true);
    final cubit = AuthCubit(repository: repo, rememberMeStorage: _NoRemember());

    await cubit.initialize();

    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(cubit.state.faceLocked, isTrue);
    expect(repo.refreshCalls, 0);
  });

  test('Face ID unlock rotates the token with /refresh, then enters the app', () async {
    useFaceId(true);
    final repo = _Repo(session: true, refreshOk: true);
    final cubit = AuthCubit(repository: repo, rememberMeStorage: _NoRemember());
    await cubit.initialize();

    final user = await cubit.unlockWithFaceId();
    expect(user?.name, 'Michael Rodriguez');
    expect(repo.refreshCalls, 1);
    expect(cubit.state.status, AuthStatus.unauthenticated); // "You're in" first

    cubit.finishSignIn();
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.faceLocked, isFalse);
  });

  test('expired session: unlock fails, session cleared, asks to sign in', () async {
    useFaceId(true);
    final repo = _Repo(session: true, refreshOk: false);
    final cubit = AuthCubit(repository: repo, rememberMeStorage: _NoRemember());
    await cubit.initialize();

    expect(await cubit.unlockWithFaceId(), isNull);
    expect(repo.session, isFalse);
    expect(cubit.state.faceLocked, isFalse);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('Face ID off: saved session opens the app directly, no onboarding', () async {
    useFaceId(false);
    final repo = _Repo(session: true, refreshOk: true);
    final cubit = AuthCubit(repository: repo, rememberMeStorage: _NoRemember());

    await cubit.initialize();
    expect(cubit.state.status, AuthStatus.authenticated);
  });

  test('no session: sign-in screen (onboarding removed)', () async {
    useFaceId(false);
    final cubit = AuthCubit(
      repository: _Repo(session: false, refreshOk: false),
      rememberMeStorage: _NoRemember(),
    );
    await cubit.initialize();
    expect(cubit.state.status, AuthStatus.unauthenticated);
  });

  test('Sign out with Face ID on locks the session; Face ID gets back in', () async {
    final store = useFaceId(true);
    await sl<TokenStorage>().saveToken('tok-1');
    final repo = _Repo(session: true, refreshOk: true);
    final cubit = AuthCubit(repository: repo, rememberMeStorage: _NoRemember());

    await cubit.logout();
    expect(repo.revoked, isFalse, reason: 'token kept for Face ID, not revoked');
    expect(store.parked, 'tok-1');
    expect(await sl<TokenStorage>().getToken(), isNull);
    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(cubit.state.faceLocked, isTrue);

    final user = await cubit.unlockWithFaceId();
    expect(user, isNotNull);
    expect(repo.refreshCalls, 1);
    expect(store.parked, isNull);
    cubit.finishSignIn();
    expect(cubit.state.status, AuthStatus.authenticated);
  });

  test('Sign out with Face ID off is a full sign-out', () async {
    final store = useFaceId(false);
    await sl<TokenStorage>().saveToken('tok-2');
    final repo = _Repo(session: true, refreshOk: true);
    final cubit = AuthCubit(repository: repo, rememberMeStorage: _NoRemember());

    await cubit.logout();
    expect(repo.revoked, isTrue);
    expect(store.parked, isNull);
    expect(cubit.state.faceLocked, isFalse);
  });

  test('App reopened after a Face ID sign-out starts locked', () async {
    final store = useFaceId(true)..parked = 'tok-3';
    final cubit = AuthCubit(
      repository: _Repo(session: false, refreshOk: true),
      rememberMeStorage: _NoRemember(),
    );
    await cubit.initialize();
    expect(cubit.state.faceLocked, isTrue);
    expect(store.parked, 'tok-3');
  });
}

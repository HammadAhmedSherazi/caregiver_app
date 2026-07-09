import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import '../../core/network/chat_realtime_service.dart';
import '../../core/network/session_expired_notifier.dart';
import '../../core/network/token_refresh_handler.dart';
import '../../data/local/remember_me_storage.dart';
import '../../data/local/remember_me_storage_impl.dart';
import '../../data/local/session_storage.dart';
import '../../data/local/session_storage_impl.dart';
import '../../data/local/token_storage.dart';
import '../../data/local/token_storage_impl.dart';
import '../../data/api/caregiver_api.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/inbox_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/visit_repository.dart';
import '../../presentation/auth/cubit/auth_cubit.dart';
import '../../presentation/home/cubit/home_cubit.dart';
import '../../presentation/profile/cubit/profile_cubit.dart';
import '../../presentation/schedule/cubit/schedule_cubit.dart';
import '../../presentation/task/cubit/task_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<TokenStorage>(TokenStorageImpl.new);
  sl.registerLazySingleton<SessionStorage>(SessionStorageImpl.new);
  sl.registerLazySingleton<SessionExpiredNotifier>(SessionExpiredNotifier.new);
  sl.registerLazySingleton<TokenRefreshHandler>(TokenRefreshHandler.new);
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      tokenStorage: sl<TokenStorage>(),
      sessionStorage: sl<SessionStorage>(),
      sessionExpiredNotifier: sl<SessionExpiredNotifier>(),
      tokenRefreshHandler: sl<TokenRefreshHandler>(),
    ),
  );
  sl.registerLazySingleton<CaregiverApi>(
    () => CaregiverApi(
      apiClient: sl<ApiClient>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );

  sl.registerLazySingleton<AuthRepository>(() {
    final repository = AuthRepositoryImpl(
      api: sl<CaregiverApi>(),
      tokenStorage: sl<TokenStorage>(),
      sessionStorage: sl<SessionStorage>(),
    );
    sl<TokenRefreshHandler>().onRefresh = repository.refreshSession;
    return repository;
  });
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(api: sl<CaregiverApi>()),
  );
  sl.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(api: sl<CaregiverApi>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(api: sl<CaregiverApi>()),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(api: sl<CaregiverApi>()),
  );
  sl.registerLazySingleton<VisitRepository>(
    () => VisitRepositoryImpl(api: sl<CaregiverApi>()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(api: sl<CaregiverApi>()),
  );
  sl.registerLazySingleton<InboxRepository>(
    () => InboxRepositoryImpl(api: sl<CaregiverApi>()),
  );
  sl.registerLazySingleton<ChatRealtimeService>(
    () => ChatRealtimeService(
      tokenStorage: sl<TokenStorage>(),
      sessionStorage: sl<SessionStorage>(),
      inboxRepository: sl<InboxRepository>(),
    ),
  );
  sl.registerLazySingleton<ClientRepository>(
    () => ClientRepositoryImpl(api: sl<CaregiverApi>()),
  );
  sl.registerLazySingleton<RememberMeStorage>(RememberMeStorageImpl.new);

  sl.registerFactory(
    () => HomeCubit(
      repository: sl<HomeRepository>(),
      visitRepository: sl<VisitRepository>(),
    ),
  );
  sl.registerFactory(
    () => ScheduleCubit(repository: sl<ScheduleRepository>()),
  );
  sl.registerFactory(
    () => ProfileCubit(repository: sl<ProfileRepository>()),
  );
  sl.registerFactory(
    () => TaskCubit(repository: sl<TaskRepository>()),
  );
  sl.registerFactory(
    () => AuthCubit(
      repository: sl<AuthRepository>(),
      rememberMeStorage: sl<RememberMeStorage>(),
    ),
  );
}

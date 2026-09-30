import 'package:get_it/get_it.dart';

import '../../core/auth/biometric_auth.dart';
import '../../core/i18n/translations.dart';
import '../../core/network/api_client.dart';
import '../../core/push/push_notification_handler.dart';
import '../../core/push/firebase_push_service.dart';
import '../constants/app_constants.dart';
import '../../core/network/chat_realtime_service.dart';
import '../../core/network/session_expired_notifier.dart';
import '../../core/network/token_refresh_handler.dart';
import '../../data/local/face_id_store.dart';
import '../../data/local/language_store.dart';
import '../../data/local/remember_me_storage.dart';
import '../../data/local/remember_me_storage_impl.dart';
import '../../data/local/session_storage.dart';
import '../../data/local/session_storage_impl.dart';
import '../../data/local/token_storage.dart';
import '../../data/local/token_storage_impl.dart';
import '../../data/api/caregiver_api.dart';
import '../../data/api/velora_api.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/change_report_repository.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/inbox_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/visit_repository.dart';
import '../../presentation/auth/cubit/auth_cubit.dart';
import '../../presentation/checkin/cubit/checkin_cubit.dart';
import '../../presentation/documents/cubit/documents_cubit.dart';
import '../../presentation/home/cubit/home_cubit.dart';
import '../../presentation/profile/cubit/profile_cubit.dart';
import '../../presentation/schedule/cubit/schedule_cubit.dart';
import '../../presentation/task/cubit/task_cubit.dart';
import '../../presentation/time/cubit/time_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  final languageStore = LanguageStore();
  await languageStore.load();
  sl.registerSingleton<LanguageStore>(languageStore);
  final translations = Translations();
  await translations.load();
  sl.registerSingleton<Translations>(translations);
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
      languageStore: sl<LanguageStore>(),
    ),
  );
  sl.registerLazySingleton<CaregiverApi>(
    () => CaregiverApi(
      apiClient: sl<ApiClient>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );
  // VELORA contract endpoints — 🚧 PLANNED, gated by ApiConfig.veloraApiEnabled.
  sl.registerLazySingleton<VeloraApi>(
    () => VeloraApi(
      apiClient: sl<ApiClient>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );

  sl.registerLazySingleton<AuthRepository>(() {
    final repository = AuthRepositoryImpl(
      api: sl<CaregiverApi>(),
      tokenStorage: sl<TokenStorage>(),
      sessionStorage: sl<SessionStorage>(),
      velora: sl<VeloraApi>(),
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
    () => ProfileRepositoryImpl(
      api: sl<CaregiverApi>(),
      velora: sl<VeloraApi>(),
      languageStore: sl<LanguageStore>(),
    ),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(api: sl<CaregiverApi>(), velora: sl<VeloraApi>()),
  );
  sl.registerLazySingleton<VisitRepository>(
    () => VisitRepositoryImpl(
      api: sl<CaregiverApi>(),
      velora: sl<VeloraApi>(),
      languageStore: sl<LanguageStore>(),
    ),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(api: sl<CaregiverApi>()),
  );
  sl.registerLazySingleton<InboxRepository>(
    () => InboxRepositoryImpl(api: sl<CaregiverApi>(), velora: sl<VeloraApi>()),
  );
  sl.registerLazySingleton<ChatRealtimeService>(
    () => ChatRealtimeService(
      tokenStorage: sl<TokenStorage>(),
      sessionStorage: sl<SessionStorage>(),
      inboxRepository: sl<InboxRepository>(),
    ),
  );
  sl.registerLazySingleton<ChangeReportRepository>(
    () => ChangeReportRepositoryImpl(velora: sl<VeloraApi>()),
  );
  sl.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(velora: sl<VeloraApi>()),
  );
  sl.registerLazySingleton<PushNotificationHandler>(
    () => PushNotificationHandler(
      devices: sl<DeviceRepository>(),
      languageStore: sl<LanguageStore>(),
      appVersion: AppConstants.appVersion,
    ),
  );
  sl.registerLazySingleton<FirebasePushService>(
    () => FirebasePushService(
      handler: sl<PushNotificationHandler>(),
      languageStore: sl<LanguageStore>(),
    ),
  );
  sl.registerLazySingleton<ClientRepository>(
    () => ClientRepositoryImpl(api: sl<CaregiverApi>()),
  );
  sl.registerLazySingleton<RememberMeStorage>(RememberMeStorageImpl.new);
  sl.registerLazySingleton<BiometricAuth>(BiometricAuth.new);
  sl.registerLazySingleton<FaceIdStore>(FaceIdStore.new);

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
    () => TimeCubit(repository: sl<VisitRepository>()),
  );
  sl.registerFactory(
    () => DocumentsCubit(repository: sl<TaskRepository>()),
  );
  sl.registerFactory(
    () => CheckInCubit(repository: sl<TaskRepository>()),
  );
  sl.registerFactory(
    () => AuthCubit(
      repository: sl<AuthRepository>(),
      rememberMeStorage: sl<RememberMeStorage>(),
    ),
  );
}

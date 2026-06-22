import 'package:get_it/get_it.dart';

import '../../data/local/remember_me_storage.dart';
import '../../data/local/remember_me_storage_impl.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../presentation/auth/cubit/auth_cubit.dart';
import '../../presentation/home/cubit/home_cubit.dart';
import '../../presentation/profile/cubit/profile_cubit.dart';
import '../../presentation/schedule/cubit/schedule_cubit.dart';
import '../../presentation/task/cubit/task_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<HomeRepository>(HomeRepositoryImpl.new);
  sl.registerLazySingleton<AuthRepository>(AuthRepositoryImpl.new);
  sl.registerLazySingleton<ScheduleRepository>(ScheduleRepositoryImpl.new);
  sl.registerLazySingleton<ProfileRepository>(ProfileRepositoryImpl.new);
  sl.registerLazySingleton<TaskRepository>(TaskRepositoryImpl.new);
  sl.registerLazySingleton<RememberMeStorage>(RememberMeStorageImpl.new);

  sl.registerFactory(
    () => HomeCubit(repository: sl<HomeRepository>()),
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

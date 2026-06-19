import 'package:get_it/get_it.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/home_repository.dart';
import '../../presentation/auth/cubit/auth_cubit.dart';
import '../../presentation/home/cubit/home_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<HomeRepository>(HomeRepositoryImpl.new);
  sl.registerLazySingleton<AuthRepository>(AuthRepositoryImpl.new);

  sl.registerFactory(() => HomeCubit(repository: sl<HomeRepository>()));
  sl.registerFactory(() => AuthCubit(repository: sl<AuthRepository>()));
}

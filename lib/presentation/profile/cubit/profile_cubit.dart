import '../../../core/base/base_cubit.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends BaseCubit<ProfileState> {
  ProfileCubit({required this.repository}) : super(const ProfileState());

  final ProfileRepository repository;

  Future<void> loadProfile({UserModel? user}) async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));

    try {
      final data = await repository.getProfile(user: user);
      emit(
        state.copyWith(
          status: ProfileStatus.success,
          data: data,
        ),
      );
    } catch (error, stackTrace) {
      logError('Failed to load profile', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'Failed to load profile. Please try again.',
        ),
      );
    }
  }
}

import '../../../core/base/base_cubit.dart';
import '../../../data/repositories/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends BaseCubit<HomeState> {
  HomeCubit({required this.repository}) : super(const HomeState());

  final HomeRepository repository;

  Future<void> loadRecipients() async {
    emit(state.copyWith(status: HomeStatus.loading, errorMessage: null));

    try {
      final recipients = await repository.getCareRecipients();
      emit(
        state.copyWith(
          status: HomeStatus.success,
          recipients: recipients,
        ),
      );
    } catch (error, stackTrace) {
      logError('Failed to load care recipients', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Failed to load care recipients. Please try again.',
        ),
      );
    }
  }

  Future<void> refresh() => loadRecipients();
}

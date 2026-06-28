import '../api/caregiver_api.dart';
import '../models/profile_page_model.dart';
import '../models/user_model.dart';

abstract class ProfileRepository {
  Future<ProfilePageData> getProfile({UserModel? user});
}

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required CaregiverApi api}) : _api = api;

  final CaregiverApi _api;

  @override
  Future<ProfilePageData> getProfile({UserModel? user}) async {
    final profile = await _api.getMe();

    final displayName = user?.name ?? profile.name;
    final firstName = displayName.split(' ').first;
    final title = profile.caregiverType.isEmpty
        ? profile.status
        : '${profile.caregiverType[0].toUpperCase()}${profile.caregiverType.substring(1)} caregiver';

    return ProfilePageData(
      headerTitle: firstName,
      name: displayName,
      title: title,
      avatarUrl: user?.avatarUrl,
      experienceYears: 0,
      visitCount: 0,
      hoursThisWeek: 0,
      targetHours: 40,
      weekChangePercent: 0,
      targetLineHours: 20,
      chartMaxHours: 30,
      weeklyHours: const [],
    );
  }
}

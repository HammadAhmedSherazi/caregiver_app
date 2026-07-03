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
    final profileFuture = _api.getMe();
    final earningsFuture = _api.getEarningsSummary();

    final profile = await profileFuture;
    final earnings = await earningsFuture;

    final displayName = user?.name ?? profile.name;
    final firstName = profile.firstName ?? displayName.split(' ').first;
    final title = profile.caregiverType.isEmpty
        ? profile.status
        : '${profile.caregiverType[0].toUpperCase()}${profile.caregiverType.substring(1)} caregiver';

    final weeklyHours = earnings.hoursSeries
        .map(
          (week) => ProfileDayHours(
            dayLabel: week.label,
            hours: week.hours,
            style: ProfileBarStyle.primary,
          ),
        )
        .toList();

    return ProfilePageData(
      headerTitle: firstName,
      name: displayName,
      title: title,
      avatarUrl: profile.avatarUrl ?? user?.avatarUrl,
      experienceYears: 0,
      visitCount: 0,
      hoursThisWeek: weeklyHours.isNotEmpty ? weeklyHours.last.hours : 0,
      targetHours: 40,
      weekChangePercent: 0,
      targetLineHours: 20,
      chartMaxHours: weeklyHours.isEmpty
          ? 30
          : weeklyHours.map((e) => e.hours).reduce((a, b) => a > b ? a : b) + 5,
      weeklyHours: weeklyHours,
    );
  }
}

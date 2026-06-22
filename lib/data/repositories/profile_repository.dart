import '../models/profile_page_model.dart';
import '../models/user_model.dart';

abstract class ProfileRepository {
  Future<ProfilePageData> getProfile({UserModel? user});
}

class ProfileRepositoryImpl implements ProfileRepository {
  static const _demoAvatarUrl = 'https://i.pravatar.cc/150?u=caregiver-mitchell';

  @override
  Future<ProfilePageData> getProfile({UserModel? user}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final displayName = user?.name ?? 'Mitchell';
    final firstName = displayName.split(' ').first;

    return ProfilePageData(
      headerTitle: firstName,
      name: displayName,
      title: 'Certified Home Healer',
      avatarUrl: user?.avatarUrl ?? _demoAvatarUrl,
      experienceYears: 3,
      visitCount: 247,
      hoursThisWeek: 28.5,
      targetHours: 40,
      weekChangePercent: 12,
      targetLineHours: 20,
      chartMaxHours: 30,
      weeklyHours: const [
        ProfileDayHours(
          dayLabel: 'M',
          hours: 30,
          style: ProfileBarStyle.accent,
        ),
        ProfileDayHours(
          dayLabel: 'T',
          hours: 19.7,
          style: ProfileBarStyle.light,
        ),
        ProfileDayHours(
          dayLabel: 'W',
          hours: 11.6,
          style: ProfileBarStyle.primary,
        ),
        ProfileDayHours(
          dayLabel: 'T',
          hours: 23.5,
          style: ProfileBarStyle.accent,
          isToday: true,
        ),
        ProfileDayHours(
          dayLabel: 'F',
          hours: 15,
          style: ProfileBarStyle.light,
        ),
      ],
    );
  }
}

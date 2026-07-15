import 'dart:math' as math;

import '../api/caregiver_api.dart';
import '../models/profile_page_model.dart';
import '../models/user_model.dart';

abstract class ProfileRepository {
  Future<ProfilePageData> getProfile({UserModel? user});
}

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required this._api});

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

    const targetLineHours = 20.0;
    final maxBarHours = weeklyHours.isEmpty
        ? 0.0
        : weeklyHours.map((e) => e.hours).reduce(math.max);
    // Keep target line inside the plot; design axis is 0–30 in steps of 5.
    final rawMax = math.max(maxBarHours + 5, math.max(targetLineHours, 30.0));
    final chartMaxHours = (rawMax / 5).ceil() * 5.0;

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
      targetLineHours: targetLineHours,
      chartMaxHours: chartMaxHours,
      weeklyHours: weeklyHours,
    );
  }
}

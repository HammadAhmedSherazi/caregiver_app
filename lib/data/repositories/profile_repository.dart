import 'dart:math' as math;

import '../api/caregiver_api.dart';
import '../models/profile_page_model.dart';
import '../models/user_model.dart';
import '../api/velora_api.dart';
import '../local/language_store.dart';
import '../models/api/velora/velora_models.dart';

abstract class ProfileRepository {
  Future<ProfilePageData> getProfile({UserModel? user});

  // 🚧 PLANNED — NOT LIVE (MOBILE_API_VELORA.md).

  /// `PUT /me/settings`. A saved `language` also becomes the
  /// `Accept-Language` for later requests.
  Future<CaregiverSettingsModel> updateSettings(CaregiverSettingsModel settings);

  /// `POST /me/info-change`. The profile does **not** change until the
  /// office approves — the result is a pending change.
  Future<InfoChangeResultModel> requestInfoChange(InfoChangeRequest request);

  /// `POST /privacy/data-request`.
  Future<PrivacyRequestResultModel> requestDataCopy();
}

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required this._api,
    required this._velora,
    required this._languageStore,
  });

  final CaregiverApi _api;
  final VeloraApi _velora;
  final LanguageStore _languageStore;

  @override
  Future<CaregiverSettingsModel> updateSettings(CaregiverSettingsModel settings) async {
    final saved = await _velora.updateSettings(settings);
    final language = saved.language;
    if (language != null) await _languageStore.set(language);
    return saved;
  }

  @override
  Future<InfoChangeResultModel> requestInfoChange(InfoChangeRequest request) {
    return _velora.requestInfoChange(request);
  }

  @override
  Future<PrivacyRequestResultModel> requestDataCopy() => _velora.requestDataCopy();

  @override
  Future<ProfilePageData> getProfile({UserModel? user}) async {
    final profileFuture = _api.getMe();
    final earningsFuture = _api.getEarningsSummary();

    final profile = await profileFuture;
    final earnings = await earningsFuture;

    // Server-chosen language (VELORA `settings.language`), when sent.
    final serverLanguage = profile.velora?.settings?.language;
    if (serverLanguage != null) await _languageStore.set(serverLanguage);

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
      email: profile.email.isEmpty ? user?.email : profile.email,
      phone: profile.phone.isEmpty ? null : profile.phone,
      address: profile.address,
      initials: profile.initials,
      isLiveIn: profile.liveIn,
    );
  }
}

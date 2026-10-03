import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

import '../../data/local/language_store.dart';
import '../../data/models/api/velora/velora_models.dart';
import '../../data/repositories/device_repository.dart';
import '../../presentation/main/app_action_router.dart';
import '../navigation/root_navigator.dart';
import '../network/api_config.dart';

/// Flutter side of push (MOBILE_API_VELORA.md §11).
///
/// **BLOCKED — BACKEND DECISION REQUIRED (D6):** the app has no FCM/APNs SDK
/// because the Firebase project and Apple push key are not available. When
/// they are, the push SDK should call:
/// * [onToken] after sign-in, on token refresh and when the language changes;
/// * [onNotificationTap] with the message `data` when a push is opened.
///
/// Server jobs (reminders, paid, missed clock-out, …) are not implemented on
/// the device — they are backend work.
class PushNotificationHandler {
  PushNotificationHandler({
    required this._devices,
    required this._languageStore,
    required this.appVersion,
  });

  final DeviceRepository _devices;
  final LanguageStore _languageStore;
  final String appVersion;

  /// This phone's push registration for [token] — `POST /devices`, and the
  /// optional push fields of `POST /login`.
  DeviceRegistrationRequest registrationFor(String token) {
    return DeviceRegistrationRequest(
      token: token,
      platform: Platform.isIOS ? 'ios' : 'android',
      appVersion: appVersion,
      language: _languageStore.current,
    );
  }

  /// Registers this phone (`POST /devices`). No-op while Group 1 is switched off.
  Future<void> onToken(String token) async {
    if (!ApiConfig.veloraGroup1Enabled || token.isEmpty) return;
    await _devices.register(registrationFor(token));
  }

  /// Push payload `data: { screen, …params }` → the matching screen.
  Future<bool> onNotificationTap(Map<String, dynamic> data) async {
    final action = AppActionModel.fromPushData(data);
    final context = rootNavigatorKey.currentContext;
    if (action == null || context == null || !context.mounted) return false;
    return AppActionRouter.open(context, action);
  }

  /// `DELETE /devices/{id}` on sign-out (best effort, before the token is
  /// cleared so the request is still authenticated).
  Future<void> onSignOut() async {
    if (!ApiConfig.veloraGroup1Enabled) return;
    try {
      await _devices.unregister();
    } catch (error) {
      debugPrint('Push device unregister failed: $error');
    }
  }

  /// After `DELETE /account` the server has already removed every push
  /// registration; only the saved device id is left to drop.
  Future<void> onAccountDeleted() => _devices.forget();
}

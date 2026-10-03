import 'package:shared_preferences/shared_preferences.dart';

import '../api/velora_api.dart';
import '../models/api/velora/velora_models.dart';

/// Push-device registration (`POST /devices`, `DELETE /devices/{id}`) —
/// 🚧 PLANNED — NOT LIVE.
///
/// The app has no FCM/APNs integration yet (blocked on Firebase/Apple
/// credentials, Open decision D6), so nothing calls [register] today. Once a
/// push SDK is added it supplies the token here after sign-in, on token
/// refresh and on language change; [unregister] runs on sign-out.
abstract class DeviceRepository {
  Future<int> register(DeviceRegistrationRequest request);
  Future<void> unregister();
  Future<int?> registeredDeviceId();

  /// Drops the saved device id without calling the server.
  Future<void> forget();
}

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({required this._velora});

  static const _keyDeviceId = 'push_device_id';

  final VeloraApi _velora;

  @override
  Future<int> register(DeviceRegistrationRequest request) async {
    final id = await _velora.registerDevice(request);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDeviceId, id);
    return id;
  }

  @override
  Future<void> unregister() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_keyDeviceId);
    if (id == null) return;
    try {
      await _velora.unregisterDevice(id);
    } finally {
      await prefs.remove(_keyDeviceId);
    }
  }

  @override
  Future<int?> registeredDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDeviceId);
  }

  @override
  Future<void> forget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeviceId);
  }
}

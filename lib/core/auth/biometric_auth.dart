import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricResult { success, cancelled, failed, lockedOut, unavailable }

/// Thin wrapper around `local_auth` so screens never touch plugin exceptions.
class BiometricAuth {
  BiometricAuth({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// True when the device has enrolled biometrics (Face ID, Touch ID,
  /// fingerprint or face unlock).
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// "Face ID" on iPhone, a generic name elsewhere.
  Future<String> label() async {
    try {
      final enrolled = await _auth.getAvailableBiometrics();
      if (!kIsWeb && Platform.isIOS) {
        return enrolled.contains(BiometricType.fingerprint)
            ? 'Touch ID'
            : 'Face ID';
      }
    } catch (_) {}
    return 'Face ID';
  }

  Future<BiometricResult> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback =>
          BiometricResult.cancelled,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          BiometricResult.lockedOut,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
          BiometricResult.unavailable,
        _ => BiometricResult.failed,
      };
    } catch (_) {
      return BiometricResult.failed;
    }
  }

  /// Dismisses an in-progress system prompt, where the platform allows it.
  Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}

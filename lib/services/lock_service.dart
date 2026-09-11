import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'database_service.dart';

/// Local app-lock: PIN code hashed with a per-install salt, plus optional
/// biometric unlock. Nothing here ever leaves the device.
class LockService {
  LockService(this._db);

  final DatabaseService _db;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const _saltKey = 'pin_salt';

  DateTime? _lastActiveAt;

  bool get hasPin => _db.settings.pinHash != null && _db.settings.pinHash!.isNotEmpty;

  bool get biometricEnabled => _db.settings.biometricEnabled;

  Future<bool> get biometricAvailable async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<String> _salt() async {
    var salt = await _secureStorage.read(key: _saltKey);
    if (salt == null) {
      salt = DateTime.now().microsecondsSinceEpoch.toString();
      await _secureStorage.write(key: _saltKey, value: salt);
    }
    return salt;
  }

  Future<String> _hash(String pin) async {
    final salt = await _salt();
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  Future<void> setPin(String pin) async {
    final settings = _db.settings;
    settings.pinHash = await _hash(pin);
    await _db.saveSettings(settings);
  }

  Future<bool> verifyPin(String pin) async {
    final settings = _db.settings;
    if (settings.pinHash == null) return false;
    final hashed = await _hash(pin);
    return hashed == settings.pinHash;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final settings = _db.settings;
    settings.biometricEnabled = enabled;
    await _db.saveSettings(settings);
  }

  Future<bool> authenticateWithBiometrics(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    final settings = _db.settings;
    settings.autoLockMinutes = minutes;
    await _db.saveSettings(settings);
  }

  int get autoLockMinutes => _db.settings.autoLockMinutes;

  /// Called whenever the app is resumed or paused, to enforce the
  /// auto-lock-after-idle policy.
  void markActive() {
    _lastActiveAt = DateTime.now();
  }

  void markBackgrounded() {
    _lastActiveAt = DateTime.now();
  }

  bool shouldLockAfterIdle() {
    if (_lastActiveAt == null) return false;
    final idleMinutes = DateTime.now().difference(_lastActiveAt!).inMinutes;
    return idleMinutes >= autoLockMinutes;
  }
}

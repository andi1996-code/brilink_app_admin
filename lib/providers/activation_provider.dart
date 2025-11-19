import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../core/device_id.dart';
import '../services/api_service.dart';
import '../core/app_navigator.dart';
import '../widgets/custom_alert.dart';

/// Provider to manage application activation with a secret key.
/// Behavior:
/// - On initialization it checks SharedPreferences for saved activation_key.
/// - activate(key) will try to validate against server endpoint `/api/activation/validate`.
/// - If server doesn't exist or call fails, it can optionally use a local fallback key (not secure).
class ActivationProvider extends ChangeNotifier {
  final ApiService apiService;

  ActivationProvider({required this.apiService}) {
    _loadActivation();
  }

  bool initialized = false;
  bool isActivated = false;
  String? activationKey;

  // Local fallback key for development only. CHANGE THIS or avoid using in production.
  static const String localFallbackKey = 'CHANGE_ME_DEV_KEY';

  // Local shared secret (HMAC) that generator & app share. If set, activation
  // will verify HMAC_SHA256(Base64) of deviceId using this secret.
  // NOTE: Storing secret in the app is not secure; keep it hidden and only use
  // in controlled environments.
  static const String localSecretKey = 'brilink_app_idnacode';

  // If you use offline public-key verification, replace with the base64 public key
  // that is paired with the generator app's private key. The generator should
  // sign the Device ID using ed25519 and return the base64 signature string.
  static const String publicKeyBase64 = 'REPLACE_WITH_PUBLIC_KEY_BASE64';

  Future<void> _loadActivation() async {
    final prefs = await SharedPreferences.getInstance();
    activationKey = prefs.getString('activation_key');
    isActivated = activationKey != null && activationKey!.isNotEmpty;
    initialized = true;
    notifyListeners();
  }

  Future<bool> activate(String key, {bool validateOnServer = true}) async {
    // Save attempt early so we can fallback if server not reachable.
    try {
      if (validateOnServer) {
        final resp = await apiService.post(
          '/api/activation/validate',
          data: {'key': key},
        );
        final data = resp.data;
        if (data != null && data is Map && data['success'] == true) {
          await _saveKey(key);
          return true;
        }
        if (data != null) {
          final msg = data['message']?.toString() ?? 'Activation key invalid';
          AppNavigator.showAlert(msg, type: AlertType.error);
          return false;
        }
        // If the server responded but not as expected, fallback to failure
        AppNavigator.showAlert(
          'Activation failed: invalid response',
          type: AlertType.error,
        );
        return false;
      } else {
        // Local validation: prefer HMAC shared-secret if configured (offline),
        // otherwise try the public-key signature method.
        // Try public-key offline verification (generator app signs DeviceID)
        try {
          // If local secret configured, verify HMAC first
          if (localSecretKey.isNotEmpty &&
              localSecretKey != 'REPLACE_WITH_SHARED_SECRET') {
            final deviceId = await DeviceId.getDeviceId();
            final algorithmHmac = Hmac.sha256();
            final secret = SecretKey(utf8.encode(localSecretKey));
            final mac = await algorithmHmac.calculateMac(
              utf8.encode(deviceId),
              secretKey: secret,
            );

            // Support hex-encoded truncated codes (e.g., "4812841B") and base64
            final hexPattern = RegExp(r'^[A-Fa-f0-9]+$');
            if (hexPattern.hasMatch(key)) {
              // hex code: use truncated leading bytes of HMAC
              final keyLen = key.length;
              if (keyLen % 2 == 0) {
                final bytesNeeded = keyLen ~/ 2;
                final truncated = mac.bytes.sublist(0, bytesNeeded);
                final hexComputed = truncated
                    .map((b) => b.toRadixString(16).padLeft(2, '0'))
                    .join()
                    .toUpperCase();
                if (hexComputed == key.toUpperCase()) {
                  await _saveKey(key);
                  return true;
                }
              }
            } else {
              final computed = base64Encode(mac.bytes);
              if (computed == key) {
                await _saveKey(key);
                return true;
              }
            }
            AppNavigator.showAlert(
              'Activation code tidak valid untuk device ini',
              type: AlertType.error,
            );
            return false;
          }

          if (publicKeyBase64.isEmpty ||
              publicKeyBase64 == 'REPLACE_WITH_PUBLIC_KEY_BASE64') {
            // If public key is not set, fallback to local fallback key only
            if (key == localFallbackKey) {
              await _saveKey(key);
              return true;
            }
            AppNavigator.showAlert(
              'Activation public key not configured',
              type: AlertType.error,
            );
            return false;
          }

          // Verify signature
          final publicKeyBytes = base64Decode(publicKeyBase64);
          final signatureBytes = base64Decode(key);
          final deviceId = await DeviceId.getDeviceId();
          final algorithm = Ed25519();
          final publicKey = SimplePublicKey(
            publicKeyBytes,
            type: KeyPairType.ed25519,
          );
          final isValid = await algorithm.verify(
            utf8.encode(deviceId),
            signature: Signature(signatureBytes, publicKey: publicKey),
          );
          if (isValid) {
            await _saveKey(key);
            return true;
          }
          AppNavigator.showAlert(
            'Activation code tidak valid untuk device ini',
            type: AlertType.error,
          );
          return false;
        } catch (e) {
          // fallback to local key if allowed
          if (key == localFallbackKey) {
            await _saveKey(key);
            return true;
          }
          AppNavigator.showAlert(
            'Activation verification failed: $e',
            type: AlertType.error,
          );
          return false;
        }
      }
    } catch (e) {
      // If server unavailable, fall back to local key check
      if (key == localFallbackKey) {
        await _saveKey(key);
        return true;
      }
      AppNavigator.showAlert('Activation error: $e', type: AlertType.error);
      return false;
    }
  }

  Future<void> _saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activation_key', key);
    activationKey = key;
    isActivated = true;
    notifyListeners();
  }

  Future<void> clearActivation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activation_key');
    activationKey = null;
    isActivated = false;
    notifyListeners();
  }
}

import 'dart:io' show Platform;
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceId {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        final map = info.toMap();
        return _selectBestId(map, fallback: 'android-device');
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        final map = info.toMap();
        return _selectBestId(map, fallback: 'ios-device');
      } else if (Platform.isLinux) {
        final info = await _deviceInfo.linuxInfo;
        final map = info.toMap();
        return _selectBestId(map, fallback: 'linux-device');
      } else if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        final map = info.toMap();
        return _selectBestId(map, fallback: 'mac-device');
      } else if (Platform.isWindows) {
        final info = await _deviceInfo.windowsInfo;
        final map = info.toMap();
        return _selectBestId(map, fallback: 'windows-device');
      }
    } catch (_) {}

    // As a last fallback, use a persistent generated id that survives app restarts
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('device_fallback_id');
    if (saved != null) return saved;
    final generated =
        'device-' +
        DateTime.now().millisecondsSinceEpoch.toString() +
        '-' +
        (Random().nextInt(999999)).toString();
    await prefs.setString('device_fallback_id', generated);
    return generated;
  }

  static String _selectBestId(
    Map<String, dynamic> map, {
    String fallback = 'device',
  }) {
    final keys = [
      'androidId',
      'id',
      'buildId',
      'display',
      'serial',
      'identifierForVendor',
      'systemGUID',
      'machine',
      'product',
      'deviceId',
    ];
    for (final k in keys) {
      if (map.containsKey(k) && map[k] != null && map[k].toString().isNotEmpty)
        return map[k].toString();
    }
    // Fallback to first available value
    if (map.values.isNotEmpty) return map.values.first.toString();
    return fallback;
  }
}

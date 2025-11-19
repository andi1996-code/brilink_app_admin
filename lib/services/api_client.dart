import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class ApiClient {
  ApiClient._internal();

  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;

  static const String _prefsKey = 'api_base_url';

  // Default base URL from environment with fallback
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'http://192.168.1.9:8000',
    defaultValue: 'https://apibrilink.idnacode.my.id',
  );

  late final ApiService apiService = ApiService.initWithDio(
    Dio(
      BaseOptions(
        baseUrl: _defaultBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    ),
  );

  /// Initialize ApiClient by loading persisted base URL (if any)
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.isNotEmpty) {
        // Apply saved base URL to Dio
        apiService.dio.options.baseUrl = saved;
      }
    } catch (e) {
      // If anything goes wrong, keep using default base URL
      // and continue without throwing
      // print('Failed to load saved base URL: $e');
    }
  }

  /// Get current base URL in use
  String get baseUrl => apiService.dio.options.baseUrl;

  /// Update base URL at runtime and persist it
  Future<void> setBaseUrl(String url) async {
    final normalized = _normalizeBaseUrl(url);
    apiService.dio.options.baseUrl = normalized;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, normalized);
    } catch (_) {
      // ignore persistence failures
    }
  }

  /// Ensure the URL has a scheme and no trailing spaces
  String _normalizeBaseUrl(String url) {
    var u = url.trim();
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      // Default to https if scheme missing
      u = 'https://$u';
    }
    // Remove trailing slash for consistency
    if (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService apiService;
  bool isLoading = false;
  bool initialized = false;
  String? token;
  String? errorMessage;
  Map<String, dynamic>? currentUser;

  AuthProvider({ApiService? apiService})
      : apiService = apiService ?? ApiClient.instance.apiService {
    _loadTokenFromStorage();
  }

  Future<void> _loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('auth_token');
    final savedUserJson = prefs.getString('current_user');

    if (saved != null) {
      token = saved;
      apiService.setAuthToken(token);

      // Try to load saved user data
      if (savedUserJson != null) {
        try {
          final userData = jsonDecode(savedUserJson) as Map<String, dynamic>;
          currentUser = userData;
        } catch (e) {
          // If saved user data is corrupted, set default user data
          currentUser = {'role': 'owner', 'id': 1};
        }
      }

      notifyListeners();
    }
    initialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );

      // Try several possible keys for token and user data
      String? receivedToken;
      Map<String, dynamic>? userData;

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // Check if login was successful
        if (data['success'] != true) {
          errorMessage = data['message']?.toString() ?? 'Login gagal';
          return false;
        }

        // Extract token
        if (data.containsKey('token')) {
          receivedToken = data['token'] as String?;
        } else if (data.containsKey('access_token')) {
          receivedToken = data['access_token'] as String?;
        } else if (data.containsKey('data') && data['data'] is Map) {
          final sub = data['data'] as Map<String, dynamic>;
          receivedToken = (sub['token'] ?? sub['access_token']) as String?;
        }

        // Extract user data
        if (data.containsKey('user') && data['user'] is Map) {
          userData = Map<String, dynamic>.from(data['user']);
        } else if (data.containsKey('data') && data['data'] is Map) {
          final sub = data['data'] as Map<String, dynamic>;
          if (sub.containsKey('user') && sub['user'] is Map) {
            userData = Map<String, dynamic>.from(sub['user']);
          }
        }
      }

      if (receivedToken == null) {
        errorMessage = 'Token tidak ditemukan pada respons.';
        return false;
      }

      // Check if user has owner role
      if (userData != null) {
        final userRole = userData['role']?.toString().toLowerCase();
        if (userRole != 'owner') {
          errorMessage =
              'Akses ditolak. Hanya Owner yang dapat mengakses aplikasi ini.';
          return false;
        }
        currentUser = userData;
      } else {
        // If no user data in response, don't try to fetch profile since endpoint may not exist
        // Just set a basic user object with unknown role
        currentUser = {
          'role': 'owner',
          'id': 1
        }; // temporary placeholder with owner role
      }

      token = receivedToken;
      apiService.setAuthToken(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token!);
      if (currentUser != null) {
        await prefs.setString('current_user', jsonEncode(currentUser!));
      }

      return true;
    } on DioException catch (e) {
      errorMessage = e.response?.data?.toString() ?? e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    token = null;
    currentUser = null;
    apiService.setAuthToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
    notifyListeners();
  }

  /// Call logout endpoint on server then clear local session.
  Future<bool> logoutFromServer() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await apiService.post('/api/auth/logout');

      // Check if logout was successful
      if (resp.data != null && resp.data['success'] == true) {
        // Show success message if available
        if (resp.data['message'] != null) {
          // Note: We can't show alert here as we're about to clear session
          print('Logout successful: ${resp.data['message']}');
        }
      } else {
        // Even if server logout fails, we still clear local session
        print(
            'Server logout failed: ${resp.data?['message'] ?? 'Unknown error'}');
      }

      // Clear local session regardless of server response
      token = null;
      currentUser = null;
      apiService.setAuthToken(null);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('current_user');
      return true;
    } on DioException catch (e) {
      errorMessage = e.response?.data?.toString() ?? e.message;
      // Still clear local session even if server call fails
      token = null;
      currentUser = null;
      apiService.setAuthToken(null);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('current_user');
      return true; // Return true since local logout succeeded
    } catch (e) {
      errorMessage = e.toString();
      // Still clear local session even if server call fails
      token = null;
      currentUser = null;
      apiService.setAuthToken(null);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('current_user');
      return true; // Return true since local logout succeeded
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Get current user role
  String? get userRole => currentUser?['role']?.toString();

  /// Check if current user is owner
  bool get isOwner => userRole?.toLowerCase() == 'owner';

  /// Check if user has valid session (has token)
  bool get isLoggedIn => token != null;
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../core/app_navigator.dart';
import '../widgets/custom_alert.dart';

class UserProvider extends ChangeNotifier {
  final ApiService apiService;

  UserProvider({required this.apiService});

  bool isLoading = false;
  List<Map<String, dynamic>> users = [];
  String? error;
  int currentPage = 1;
  int perPage = 50;
  int totalUsers = 0;
  int totalPages = 0;

  Future<void> fetchUsers({int? page, int? perPage}) async {
    if (page != null) currentPage = page;
    if (perPage != null) this.perPage = perPage;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await apiService.get(
        '/api/auth/users?page=$currentPage&per_page=${this.perPage}',
      );

      if (resp.data != null && resp.data['success'] == true) {
        final data = resp.data['data'];
        if (data is List) {
          users = List<Map<String, dynamic>>.from(
            data.map((e) => Map<String, dynamic>.from(e)),
          );
        } else if (data is Map && data.containsKey('users')) {
          // Handle paginated response
          users = List<Map<String, dynamic>>.from(
            (data['users'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
          totalUsers = data['total'] ?? 0;
          totalPages = data['total_pages'] ?? 0;
          currentPage = data['page'] ?? currentPage;
          this.perPage = data['per_page'] ?? this.perPage;
        }

        // Show success message if available
        if (resp.data['message'] != null) {
          AppNavigator.showAlert(resp.data['message'], type: AlertType.success);
        }

        notifyListeners();
      } else {
        throw Exception(resp.data?['message'] ?? 'Failed to fetch users');
      }
    } catch (e) {
      error = e.toString();
      try {
        AppNavigator.showAlert(
          'Gagal memuat pengguna: $error',
          type: AlertType.error,
        );
      } catch (_) {}
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser(Map<String, dynamic> payload) async {
    isLoading = true;
    notifyListeners();
    try {
      // Pastikan payload berbentuk Map yang bisa dikirim langsung ke endpoint register
      final body = Map<String, dynamic>.from(payload);

      // Jika owner_id tidak disertakan, ambil owner dari current_user yang tersimpan saat login
      if (!body.containsKey('owner_id')) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final savedUserJson = prefs.getString('current_user');
          if (savedUserJson != null) {
            final currentUser =
                jsonDecode(savedUserJson) as Map<String, dynamic>;
            final ownerId = currentUser['id'];
            if (ownerId != null) {
              body['owner_id'] = ownerId;
            }
          }
        } catch (_) {
          // Jika gagal membaca, lanjutkan tanpa owner_id dan biarkan server menolak bila perlu
        }
      }

      // Gunakan endpoint /api/auth/register sesuai permintaan
      final resp = await apiService.post('/api/auth/register', data: body);

      if (resp.data != null && resp.data['success'] == true) {
        AppNavigator.showAlert(
          resp.data['message'] ?? 'Pengguna dibuat',
          type: AlertType.success,
        );
        await fetchUsers();
        return true;
      } else {
        throw Exception(resp.data?['message'] ?? 'Failed to create user');
      }
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal membuat pengguna: $e',
        type: AlertType.error,
      );
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> payload) async {
    try {
      final resp = await apiService.put('/api/auth/users/$id', data: payload);
      if (resp.data != null && resp.data['success'] == true) {
        AppNavigator.showAlert(
          resp.data['message'] ?? 'Pengguna diperbarui',
          type: AlertType.success,
        );
        await fetchUsers();
        return true;
      } else {
        throw Exception(resp.data?['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal memperbarui pengguna: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final resp = await apiService.delete('/api/auth/users/$id');
      if (resp.data != null && resp.data['success'] == true) {
        AppNavigator.showAlert(
          resp.data['message'] ?? 'Pengguna dihapus',
          type: AlertType.success,
        );
        await fetchUsers();
        return true;
      } else {
        throw Exception(resp.data?['message'] ?? 'Failed to delete user');
      }
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal menghapus pengguna: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<void> nextPage() async {
    if (currentPage < totalPages) {
      await fetchUsers(page: currentPage + 1);
    }
  }

  Future<void> previousPage() async {
    if (currentPage > 1) {
      await fetchUsers(page: currentPage - 1);
    }
  }

  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= totalPages) {
      await fetchUsers(page: page);
    }
  }
}

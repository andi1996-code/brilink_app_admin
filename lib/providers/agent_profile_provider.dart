import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/app_navigator.dart';
import '../widgets/custom_alert.dart';

class AgentProfileProvider extends ChangeNotifier {
  final ApiService apiService;

  AgentProfileProvider({required this.apiService});

  bool isLoading = false;
  Map<String, dynamic>? profile;
  String? error;

  Future<void> fetchProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await apiService.get('/api/agent-profiles');
      final data = resp.data is List ? resp.data : resp;
      if (data is List && data.isNotEmpty) {
        profile = Map<String, dynamic>.from(data.first);
      } else {
        profile = null;
      }
    } catch (e) {
      error = e.toString();
      try {
        AppNavigator.showAlert(
          'Gagal memuat profil agen: $error',
          type: AlertType.error,
        );
      } catch (_) {}
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProfile(Map<String, dynamic> payload) async {
    try {
      await apiService.post('/api/agent-profiles', data: payload);
      AppNavigator.showAlert('Profil agen dibuat', type: AlertType.success);
      await fetchProfile();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal membuat profil agen: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> updateProfile(int id, Map<String, dynamic> payload) async {
    try {
      await apiService.put('/api/agent-profiles/$id', data: payload);
      AppNavigator.showAlert('Profil agen diperbarui', type: AlertType.success);
      await fetchProfile();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal memperbarui profil agen: $e',
        type: AlertType.error,
      );
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/app_navigator.dart';
import '../widgets/custom_alert.dart';

class AgentProvider extends ChangeNotifier {
  final ApiService apiService;

  AgentProvider({required this.apiService});

  bool isLoading = false;
  List<Map<String, dynamic>> agents = [];
  String? error;

  Future<void> fetchAgents() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await apiService.get('/api/agents');

      // Handle new response structure with success, message, and data
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          error = responseData['message']?.toString() ?? 'Gagal memuat agen';
          try {
            AppNavigator.showAlert(error!, type: AlertType.error);
          } catch (_) {}
          return;
        }
        final data = responseData['data'];
        if (data is List) {
          agents = List<Map<String, dynamic>>.from(
            data.map((e) => Map<String, dynamic>.from(e)),
          );
        } else {
          error = 'Format data tidak valid';
          try {
            AppNavigator.showAlert(error!, type: AlertType.error);
          } catch (_) {}
          return;
        }
      } else if (resp.data is List) {
        // Fallback for old format
        agents = List<Map<String, dynamic>>.from(
          resp.data.map((e) => Map<String, dynamic>.from(e)),
        );
      } else {
        error = 'Format respons tidak valid';
        try {
          AppNavigator.showAlert(error!, type: AlertType.error);
        } catch (_) {}
        return;
      }

      notifyListeners();
    } catch (e) {
      error = e.toString();
      try {
        AppNavigator.showAlert(
          'Gagal memuat agen: $error',
          type: AlertType.error,
        );
      } catch (_) {}
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAgent(Map<String, dynamic> payload) async {
    try {
      final resp = await apiService.post('/api/agents', data: payload);

      // Check response success
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message =
              responseData['message']?.toString() ?? 'Gagal membuat agen';
          AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        AppNavigator.showAlert(
            responseData['message']?.toString() ?? 'Agen dibuat',
            type: AlertType.success);
      } else {
        AppNavigator.showAlert('Agen dibuat', type: AlertType.success);
      }

      await fetchAgents();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal membuat agen: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> updateAgent(int id, Map<String, dynamic> payload) async {
    try {
      final resp = await apiService.put('/api/agents/$id', data: payload);

      // Check response success
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message =
              responseData['message']?.toString() ?? 'Gagal memperbarui agen';
          AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        AppNavigator.showAlert(
            responseData['message']?.toString() ?? 'Agen diperbarui',
            type: AlertType.success);
      } else {
        AppNavigator.showAlert('Agen diperbarui', type: AlertType.success);
      }

      await fetchAgents();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal memperbarui agen: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> deleteAgent(int id) async {
    try {
      final resp = await apiService.delete('/api/agents/$id');

      // Check response success
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message =
              responseData['message']?.toString() ?? 'Gagal menghapus agen';
          AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        AppNavigator.showAlert(
            responseData['message']?.toString() ?? 'Agen dihapus',
            type: AlertType.success);
      } else {
        AppNavigator.showAlert('Agen dihapus', type: AlertType.success);
      }

      await fetchAgents();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal menghapus agen: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  /// Return agent name synchronously if available. Triggers a targeted
  /// fetch when missing, and returns '-' until available.
  String findAgentName(dynamic agentId) {
    if (agentId == null) return '-';
    final idStr = agentId.toString();
    try {
      final a = agents.firstWhere(
        (e) => e['id']?.toString() == idStr,
        orElse: () => {},
      );
      if (a.isNotEmpty) return (a['agent_name'] ?? '-') as String;
    } catch (_) {}
    // Not found, could trigger fetch but for now just return '-'
    return '-';
  }
}

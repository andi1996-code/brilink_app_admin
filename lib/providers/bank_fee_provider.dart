import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/app_navigator.dart';
import '../widgets/custom_alert.dart';

class BankFeeProvider extends ChangeNotifier {
  final ApiService apiService;

  BankFeeProvider({required this.apiService});

  bool isLoading = false;
  List<Map<String, dynamic>> fees = [];
  String? error;

  Future<void> fetchFees() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await apiService.get('/api/bank-fees');
      if (resp.data != null && resp.data['success'] == true) {
        final data = resp.data['data'];
        fees = List<Map<String, dynamic>>.from(
          data.map((e) => Map<String, dynamic>.from(e)),
        );
        if (resp.data['message'] != null) {
          AppNavigator.showAlert(resp.data['message'], type: AlertType.success);
        }
      } else {
        throw Exception(resp.data?['message'] ?? 'Failed to fetch bank fees');
      }
      notifyListeners();
    } catch (e) {
      error = e.toString();
      try {
        AppNavigator.showAlert(
          'Gagal memuat bank fees: $error',
          type: AlertType.error,
        );
      } catch (_) {}
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createFee(Map<String, dynamic> payload) async {
    try {
      final resp = await apiService.post('/api/bank-fees', data: payload);
      if (resp.data != null && resp.data['success'] == true) {
        AppNavigator.showAlert(
          resp.data['message'] ?? 'Biaya bank dibuat',
          type: AlertType.success,
        );
        await fetchFees();
        return true;
      } else {
        throw Exception(resp.data?['message'] ?? 'Failed to create bank fee');
      }
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal membuat biaya bank: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> updateFee(int id, Map<String, dynamic> payload) async {
    try {
      final resp = await apiService.put('/api/bank-fees/$id', data: payload);
      if (resp.data != null && resp.data['success'] == true) {
        AppNavigator.showAlert(
          resp.data['message'] ?? 'Biaya bank diperbarui',
          type: AlertType.success,
        );
        await fetchFees();
        return true;
      } else {
        throw Exception(resp.data?['message'] ?? 'Failed to update bank fee');
      }
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal memperbarui biaya bank: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> deleteFee(int id) async {
    try {
      final resp = await apiService.delete('/api/bank-fees/$id');
      if (resp.data != null && resp.data['success'] == true) {
        AppNavigator.showAlert(
          resp.data['message'] ?? 'Biaya bank dihapus',
          type: AlertType.success,
        );
        await fetchFees();
        return true;
      } else {
        throw Exception(resp.data?['message'] ?? 'Failed to delete bank fee');
      }
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal menghapus biaya bank: $e',
        type: AlertType.error,
      );
      return false;
    }
  }
}

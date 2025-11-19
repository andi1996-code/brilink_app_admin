import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/app_navigator.dart';
import '../widgets/custom_alert.dart';

class ServiceFeeProvider extends ChangeNotifier {
  final ApiService apiService;

  ServiceFeeProvider({required this.apiService});

  bool isLoading = false;
  List<Map<String, dynamic>> fees = [];
  String? error;

  Future<void> fetchFees() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await apiService.get('/api/service-fees');

      // Handle new response structure with success, message, and data
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          error = responseData['message']?.toString() ??
              'Gagal memuat biaya layanan';
          try {
            AppNavigator.showAlert(error!, type: AlertType.error);
          } catch (_) {}
          return;
        }
        final data = responseData['data'];
        if (data is List) {
          fees = List<Map<String, dynamic>>.from(
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
        fees = List<Map<String, dynamic>>.from(
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
          'Gagal memuat biaya layanan: $error',
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
      final resp = await apiService.post('/api/service-fees', data: payload);

      // Check response success
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message = responseData['message']?.toString() ??
              'Gagal membuat biaya layanan';
          AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        AppNavigator.showAlert(
            responseData['message']?.toString() ?? 'Biaya layanan dibuat',
            type: AlertType.success);
      } else {
        AppNavigator.showAlert('Biaya layanan dibuat', type: AlertType.success);
      }

      await fetchFees();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal membuat biaya layanan: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> updateFee(int id, Map<String, dynamic> payload) async {
    try {
      final resp = await apiService.put('/api/service-fees/$id', data: payload);

      // Check response success
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message = responseData['message']?.toString() ??
              'Gagal memperbarui biaya layanan';
          AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        AppNavigator.showAlert(
            responseData['message']?.toString() ?? 'Biaya layanan diperbarui',
            type: AlertType.success);
      } else {
        AppNavigator.showAlert(
          'Biaya layanan diperbarui',
          type: AlertType.success,
        );
      }

      await fetchFees();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal memperbarui biaya layanan: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> deleteFee(int id) async {
    try {
      final resp = await apiService.delete('/api/service-fees/$id');

      // Check response success
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message = responseData['message']?.toString() ??
              'Gagal menghapus biaya layanan';
          AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        AppNavigator.showAlert(
            responseData['message']?.toString() ?? 'Biaya layanan dihapus',
            type: AlertType.success);
      } else {
        AppNavigator.showAlert('Biaya layanan dihapus',
            type: AlertType.success);
      }

      await fetchFees();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal menghapus biaya layanan: $e',
        type: AlertType.error,
      );
      return false;
    }
  }
}

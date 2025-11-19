import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/app_navigator.dart';
import '../widgets/custom_alert.dart';

class ServiceProvider extends ChangeNotifier {
  final ApiService apiService;

  ServiceProvider({required this.apiService}) {
    // Fetch services proactively when the provider is instantiated so
    // dependent screens (e.g., ServiceFee) don't need the user to open
    // the Service screen first.
    Future.microtask(() => fetchServices());
  }

  bool isLoading = false;
  List<Map<String, dynamic>> services = [];
  String? error;
  // track in-flight per-id fetches to avoid duplicated requests
  final Set<String> _pendingFetchIds = {};

  /// Return true if a per-id fetch is currently in progress for [serviceId].
  bool isFetchingId(dynamic serviceId) {
    if (serviceId == null) return false;
    return _pendingFetchIds.contains(serviceId.toString());
  }

  Future<void> fetchServices() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await apiService.get('/api/services');

      // Handle new response structure with success, message, and data
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          error = responseData['message']?.toString() ?? 'Gagal memuat layanan';
          try {
            AppNavigator.showAlert(error!, type: AlertType.error);
          } catch (_) {}
          return;
        }
        final data = responseData['data'];
        if (data is List) {
          services = List<Map<String, dynamic>>.from(
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
        services = List<Map<String, dynamic>>.from(
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
          'Gagal memuat layanan: $error',
          type: AlertType.error,
        );
      } catch (_) {}
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch a single service by id and insert/update into local cache.
  /// Returns the service name if found, otherwise null.
  Future<String?> fetchServiceById(dynamic serviceId) async {
    if (serviceId == null) return null;
    final idStr = serviceId.toString();
    if (_pendingFetchIds.contains(idStr)) return null;
    _pendingFetchIds.add(idStr);
    try {
      final resp = await apiService.get('/api/services/$idStr');
      final data = (resp is List) ? resp : (resp.data ?? resp);
      Map<String, dynamic>? item;
      if (data is Map) {
        item = Map<String, dynamic>.from(data);
      } else if (data is List && data.isNotEmpty) {
        item = Map<String, dynamic>.from(data.first);
      }
      if (item != null && item.isNotEmpty) {
        // remove any stale entry with same id then add
        services.removeWhere((e) => e['id']?.toString() == idStr);
        services.add(item);
        notifyListeners();
        return item['name']?.toString();
      }
    } catch (_) {
      // ignore network errors here; UI will fallback
    } finally {
      _pendingFetchIds.remove(idStr);
    }
    return null;
  }

  /// Return service name synchronously if available. If not found, trigger
  /// a background fetch and return '-' so UI can update when data arrives.
  String findServiceName(dynamic serviceId) {
    if (serviceId == null) return '-';
    final idStr = serviceId.toString();
    try {
      final s = services.firstWhere(
        (e) => e['id']?.toString() == idStr,
        orElse: () => {},
      );
      if (s.isNotEmpty) return (s['name'] ?? '-') as String;
    } catch (_) {}
    // not found: attempt targeted background fetch for this id
    if (!_pendingFetchIds.contains(idStr)) {
      // fire-and-forget; UI listens to provider and will rebuild when item arrives
      fetchServiceById(serviceId);
    }
    return '-';
  }

  Future<bool> createService(Map<String, dynamic> payload) async {
    try {
      final resp = await apiService.post('/api/services', data: payload);

      // Check response success
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message =
              responseData['message']?.toString() ?? 'Gagal membuat layanan';
          AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        AppNavigator.showAlert(
            responseData['message']?.toString() ?? 'Layanan dibuat',
            type: AlertType.success);
      } else {
        AppNavigator.showAlert('Layanan dibuat', type: AlertType.success);
      }

      await fetchServices();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal membuat layanan: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> updateService(int id, Map<String, dynamic> payload) async {
    try {
      final resp = await apiService.put('/api/services/$id', data: payload);

      // Check response success
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message = responseData['message']?.toString() ??
              'Gagal memperbarui layanan';
          AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        AppNavigator.showAlert(
            responseData['message']?.toString() ?? 'Layanan diperbarui',
            type: AlertType.success);
      } else {
        AppNavigator.showAlert('Layanan diperbarui', type: AlertType.success);
      }

      await fetchServices();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal memperbarui layanan: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> deleteService(int id) async {
    try {
      final resp = await apiService.delete('/api/services/$id');

      // Check response success
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message =
              responseData['message']?.toString() ?? 'Gagal menghapus layanan';
          AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        AppNavigator.showAlert(
            responseData['message']?.toString() ?? 'Layanan dihapus',
            type: AlertType.success);
      } else {
        AppNavigator.showAlert('Layanan dihapus', type: AlertType.success);
      }

      await fetchServices();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal menghapus layanan: $e',
        type: AlertType.error,
      );
      return false;
    }
  }
}

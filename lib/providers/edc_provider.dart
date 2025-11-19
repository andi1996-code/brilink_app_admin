import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/app_navigator.dart';
import '../widgets/custom_alert.dart';

class EdcProvider extends ChangeNotifier {
  final ApiService apiService;

  EdcProvider({required this.apiService});

  bool isLoading = false;
  List<Map<String, dynamic>> machines = [];
  String? error;
  final Set<String> _pendingFetchIds = {};

  Future<void> fetchMachines() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await apiService.get('/api/edc-machines');

      // Handle new response structure with success, message, and data
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          error =
              responseData['message']?.toString() ?? 'Gagal memuat mesin EDC';
          try {
            AppNavigator.showAlert(error!, type: AlertType.error);
          } catch (_) {}
          return;
        }
        final data = responseData['data'];
        if (data is List) {
          machines = List<Map<String, dynamic>>.from(
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
        machines = List<Map<String, dynamic>>.from(
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
          'Gagal memuat mesin EDC: $error',
          type: AlertType.error,
        );
      } catch (_) {}
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Return true if a per-id fetch is currently in progress for [machineId].
  bool isFetchingId(dynamic machineId) {
    if (machineId == null) return false;
    return _pendingFetchIds.contains(machineId.toString());
  }

  /// Fetch a single EDC machine by id and insert/update into local cache.
  Future<String?> fetchMachineById(dynamic machineId) async {
    if (machineId == null) return null;
    final idStr = machineId.toString();
    if (_pendingFetchIds.contains(idStr)) return null;
    _pendingFetchIds.add(idStr);
    try {
      final resp = await apiService.get('/api/edc-machines/$idStr');
      dynamic body;
      try {
        body = resp.data;
      } catch (_) {
        body = resp;
      }

      Map<String, dynamic>? item;
      if (body is Map && body.containsKey('id')) {
        item = Map<String, dynamic>.from(body);
      } else if (body is List && body.isNotEmpty) {
        item = Map<String, dynamic>.from(body.first);
      }

      if (item != null && item.isNotEmpty) {
        machines.removeWhere((e) => e['id']?.toString() == idStr);
        machines.add(item);
        notifyListeners();
        return item['name']?.toString();
      }
    } catch (_) {
      // ignore
    } finally {
      _pendingFetchIds.remove(idStr);
    }
    return null;
  }

  /// Return machine name synchronously if available. Triggers a targeted
  /// fetch when missing, and returns '-' until available.
  String findMachineName(dynamic machineId) {
    if (machineId == null) return '-';
    final idStr = machineId.toString();
    try {
      final s = machines.firstWhere(
        (e) => e['id']?.toString() == idStr,
        orElse: () => {},
      );
      if (s.isNotEmpty) return (s['name'] ?? '-') as String;
    } catch (_) {}
    if (!_pendingFetchIds.contains(idStr)) {
      fetchMachineById(machineId);
    }
    return '-';
  }

  Future<bool> createMachine(Map<String, dynamic> payload) async {
    try {
      // Siapkan body dari payload dan hilangkan field opsional jika kosong/null
      final body = Map<String, dynamic>.from(payload);
      if (!body.containsKey('agent_profile_id') ||
          body['agent_profile_id'] == null ||
          body['agent_profile_id'].toString().trim().isEmpty) {
        body.remove('agent_profile_id');
      }

      final resp = await apiService.post('/api/edc-machines', data: body);

      // Check response success
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message =
              responseData['message']?.toString() ?? 'Gagal membuat mesin EDC';
          AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        AppNavigator.showAlert(
          responseData['message']?.toString() ?? 'Mesin EDC dibuat',
          type: AlertType.success,
        );
      } else {
        AppNavigator.showAlert('Mesin EDC dibuat', type: AlertType.success);
      }

      await fetchMachines();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal membuat mesin EDC: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> updateMachine(int id, Map<String, dynamic> payload) async {
    try {
      final resp = await apiService.put('/api/edc-machines/$id', data: payload);

      // Check response success
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message =
              responseData['message']?.toString() ??
              'Gagal memperbarui mesin EDC';
          AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        AppNavigator.showAlert(
          responseData['message']?.toString() ?? 'Mesin EDC diperbarui',
          type: AlertType.success,
        );
      } else {
        AppNavigator.showAlert('Mesin EDC diperbarui', type: AlertType.success);
      }

      await fetchMachines();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal memperbarui mesin EDC: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> deleteMachine(int id) async {
    try {
      final resp = await apiService.delete('/api/edc-machines/$id');

      // Check response success
      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message =
              responseData['message']?.toString() ??
              'Gagal menghapus mesin EDC';
          AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        AppNavigator.showAlert(
          responseData['message']?.toString() ?? 'Mesin EDC dihapus',
          type: AlertType.success,
        );
      } else {
        AppNavigator.showAlert('Mesin EDC dihapus', type: AlertType.success);
      }

      await fetchMachines();
      return true;
    } catch (e) {
      AppNavigator.showAlert(
        'Gagal menghapus mesin EDC: $e',
        type: AlertType.error,
      );
      return false;
    }
  }

  Future<bool> addSaldo(int id, int amount, {bool showAlert = true}) async {
    try {
      final resp = await apiService.post(
        '/api/edc-machines/$id/add-saldo',
        data: {'amount': amount},
      );

      if (resp.data is Map<String, dynamic>) {
        final responseData = resp.data as Map<String, dynamic>;
        if (responseData['success'] != true) {
          final message =
              responseData['message']?.toString() ?? 'Gagal menambah saldo EDC';
          if (showAlert) AppNavigator.showAlert(message, type: AlertType.error);
          return false;
        }
        if (showAlert)
          AppNavigator.showAlert(
            responseData['message']?.toString() ??
                'Saldo EDC berhasil ditambahkan',
            type: AlertType.success,
          );
      } else {
        if (showAlert)
          AppNavigator.showAlert(
            'Saldo EDC berhasil ditambahkan',
            type: AlertType.success,
          );
      }

      // Refresh this specific machine so UI updates; fallback to fetching all
      await fetchMachineById(id);
      await fetchMachines();
      return true;
    } catch (e) {
      if (showAlert)
        AppNavigator.showAlert(
          'Gagal menambah saldo EDC: $e',
          type: AlertType.error,
        );
      return false;
    }
  }
}

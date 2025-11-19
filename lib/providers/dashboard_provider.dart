import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/app_navigator.dart';
import '../widgets/custom_alert.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService apiService;

  DashboardProvider({required this.apiService});

  bool isLoading = false;
  int totalRevenueToday = 0;
  int totalTransactionsToday = 0;
  int saldoTunai = 0;
  int saldoEdc = 0;
  int activeKasir = 0;
  List<Map<String, dynamic>> topServicesByRevenue = [];
  List<Map<String, dynamic>> topServicesByVolume = [];
  List<Map<String, dynamic>> dailyTrend = [];
  List<Map<String, dynamic>> recentTransactions = [];
  Map<String, dynamic>? period;
  String? error;

  int _parseAmount(dynamic v) {
    if (v == null) return 0;
    final s = v.toString().trim().replaceAll(',', '.');
    final cleaned = s.replaceAll(RegExp('[^0-9\.]'), '');
    final d = double.tryParse(cleaned);
    if (d != null) return d.round();
    final digits = s.replaceAll(RegExp('[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  Future<void> loadDashboard() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await apiService.get('/api/dashboard');
      if (resp.data != null && resp.data['success'] == true) {
        final data = resp.data['data'];

        // Parse main metrics
        totalRevenueToday = _parseAmount(data?['total_revenue_today']);
        totalTransactionsToday = (data?['total_transactions_today'] ?? 0) is int
            ? data['total_transactions_today']
            : int.tryParse('${data?['total_transactions_today'] ?? 0}') ?? 0;

        saldoTunai = _parseAmount(data?['saldo_tunai']);
        saldoEdc = _parseAmount(data?['saldo_edc']);

        activeKasir = (data?['active_kasir'] ?? 0) is int
            ? data['active_kasir']
            : int.tryParse('${data?['active_kasir'] ?? 0}') ?? 0;

        // Period information
        period = data?['period'] != null
            ? Map<String, dynamic>.from(data['period'])
            : null;

        // top services by revenue
        topServicesByRevenue = [];
        if (data?['top_services_by_revenue'] is List) {
          topServicesByRevenue = List<Map<String, dynamic>>.from(
            (data['top_services_by_revenue'] as List).map(
              (e) => Map<String, dynamic>.from(e),
            ),
          ).map((m) {
            // ensure revenue parsed to int
            final rev = m['revenue'];
            m['revenue_int'] = _parseAmount(rev);
            return m;
          }).toList();
        }

        // top services by volume
        topServicesByVolume = [];
        if (data?['top_services_by_volume'] is List) {
          topServicesByVolume = List<Map<String, dynamic>>.from(
            (data['top_services_by_volume'] as List).map(
              (e) => Map<String, dynamic>.from(e),
            ),
          ).map((m) {
            m['revenue_int'] = _parseAmount(m['revenue']);
            return m;
          }).toList();
        }

        // daily trend
        dailyTrend = [];
        if (data?['daily_trend'] is List) {
          dailyTrend = List<Map<String, dynamic>>.from(
            (data['daily_trend'] as List).map(
              (e) => Map<String, dynamic>.from(e),
            ),
          );
        }

        // recent transactions
        recentTransactions = [];
        if (data?['recent_transactions'] is List) {
          recentTransactions = List<Map<String, dynamic>>.from(
            (data['recent_transactions'] as List).map(
              (e) => Map<String, dynamic>.from(e),
            ),
          ).map((m) {
            // normalize amount
            m['amount_int'] = _parseAmount(m['amount']);
            return m;
          }).toList();
        }

        // Show success message if available
        if (resp.data['message'] != null) {
          AppNavigator.showAlert(resp.data['message'], type: AlertType.success);
        }

        notifyListeners();
      } else {
        throw Exception(
            resp.data?['message'] ?? 'Failed to load dashboard data');
      }
    } catch (e) {
      error = e.toString();
      try {
        AppNavigator.showAlert(
          'Gagal memuat dashboard: $error',
          type: AlertType.error,
        );
      } catch (_) {}
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadDashboard();
}

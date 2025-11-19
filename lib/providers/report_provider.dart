import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/app_navigator.dart';
import '../widgets/custom_alert.dart';

class ReportProvider extends ChangeNotifier {
  final ApiService apiService;

  ReportProvider({required this.apiService});

  bool isLoading = false;
  String? error;

  // summary fields
  Map<String, dynamic> summary = {};
  Map<String, dynamic> period = {};
  Map<String, dynamic> feesBreakdown = {};

  // data collections
  List<Map<String, dynamic>> series = []; // daily_breakdown
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> agentPerformance = [];
  List<Map<String, dynamic>> edcPerformance = [];
  List<Map<String, dynamic>> serviceBreakdown = [];

  Future<void> fetchReports({
    required String range,
    int perPage = 30,
    DateTimeRange? customRange,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final query = <String, dynamic>{};

      // Map range to period parameter as used in the API
      String periodParam;
      switch (range) {
        case 'daily':
          periodParam = 'daily';
          break;
        case 'weekly':
          periodParam = 'weekly';
          break;
        case 'monthly':
          periodParam = 'monthly';
          break;
        case 'custom':
          periodParam = 'custom';
          if (customRange != null) {
            query['start_date'] =
                customRange.start.toIso8601String().split('T')[0];
            query['end_date'] = customRange.end.toIso8601String().split('T')[0];
          }
          break;
        default:
          periodParam = 'daily';
      }

      query['period'] = periodParam;
      query['per_page'] = perPage.toString();

      final resp = await apiService.get(
        '/api/reports',
        queryParameters: query,
      );

      dynamic body;
      try {
        body = resp.data;
      } catch (_) {
        body = resp;
      }

      // Reset previous
      summary = {};
      period = {};
      feesBreakdown = {};
      series = [];
      transactions = [];
      agentPerformance = [];
      edcPerformance = [];
      serviceBreakdown = [];

      if (body is Map) {
        // Handle new response structure with success, message, and data
        if (body['success'] != true) {
          error = body['message']?.toString() ?? 'Gagal memuat laporan';
          try {
            AppNavigator.showAlert(error!, type: AlertType.error);
          } catch (_) {}
          return;
        }

        final data = body['data'];
        if (data is Map) {
          // period info
          if (data['period'] is Map) {
            period = Map<String, dynamic>.from(data['period']);
          }

          // summary
          if (data['summary'] is Map) {
            summary = Map<String, dynamic>.from(data['summary']);
          }

          // fees breakdown
          if (data['fees_breakdown'] is Map) {
            feesBreakdown = Map<String, dynamic>.from(data['fees_breakdown']);
          }

          // daily breakdown (series)
          if (data['daily_breakdown'] is List) {
            series = List<Map<String, dynamic>>.from(
              (data['daily_breakdown'] as List)
                  .map((e) => Map<String, dynamic>.from(e)),
            );
          }

          // agent performance
          if (data['agent_performance'] is List) {
            agentPerformance = List<Map<String, dynamic>>.from(
              (data['agent_performance'] as List)
                  .map((e) => Map<String, dynamic>.from(e)),
            );
          }

          // edc performance
          if (data['edc_performance'] is List) {
            edcPerformance = List<Map<String, dynamic>>.from(
              (data['edc_performance'] as List)
                  .map((e) => Map<String, dynamic>.from(e)),
            );
          }

          // service breakdown
          if (data['service_breakdown'] is List) {
            serviceBreakdown = List<Map<String, dynamic>>.from(
              (data['service_breakdown'] as List)
                  .map((e) => Map<String, dynamic>.from(e)),
            );
          }

          // transactions may be paginated under 'transactions.data' or direct list
          if (data['transactions'] is Map &&
              data['transactions']['data'] is List) {
            transactions = List<Map<String, dynamic>>.from(
              (data['transactions']['data'] as List).map(
                (e) => Map<String, dynamic>.from(e),
              ),
            );
          } else if (data['transactions'] is List) {
            transactions = List<Map<String, dynamic>>.from(
              (data['transactions'] as List).map(
                (e) => Map<String, dynamic>.from(e),
              ),
            );
          }
        }
      } else if (body is List) {
        // legacy: if API returns simple list
        transactions = List<Map<String, dynamic>>.from(
          body.map((e) => Map<String, dynamic>.from(e)),
        );
      }
      notifyListeners();
    } catch (e) {
      error = e.toString();
      try {
        AppNavigator.showAlert(
          'Gagal memuat laporan: $error',
          type: AlertType.error,
        );
      } catch (_) {}
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

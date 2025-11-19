import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Provider expects the shared ApiService instance via named parameter `apiService`.
class CashFlowProvider extends ChangeNotifier {
  final ApiService apiService;
  CashFlowProvider({required this.apiService});

  bool isLoading = false;
  String? error;
  List<Map<String, dynamic>> items = [];
  // Removed pagination fields since API doesn't use limit/offset
  // cache of user id -> display name
  final Map<int, String> _userNames = {};
  // cache of agent profile id -> display name
  final Map<int, String> _agentProfileNames = {};

  /// Return a display name for a user id. Uses cache when available,
  /// otherwise tries GET /api/users/{id} and reads common name fields.
  Future<String> getUserName(int? userId) async {
    if (userId == null) return 'User: -';
    if (_userNames.containsKey(userId)) return _userNames[userId]!;
    try {
      final res = await apiService.get('/api/users/$userId');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data;
        String name = 'User #$userId';
        if (data is Map<String, dynamic>) {
          name = (data['name'] ??
                  data['full_name'] ??
                  data['username'] ??
                  data['email'] ??
                  name)
              .toString();
        } else if (data is String) {
          name = data;
        }
        _userNames[userId] = name;
        notifyListeners();
        return name;
      }
    } catch (_) {
      // ignore and fallback
    }
    final fallback = 'User #$userId';
    _userNames[userId] = fallback;
    return fallback;
  }

  /// Return a display name for an agent profile id. Uses cache when available,
  /// otherwise tries GET /api/agent-profiles/{id} and reads common name fields.
  Future<String> getAgentProfileName(int? agentProfileId) async {
    if (agentProfileId == null) return 'Agent Profile: -';
    if (_agentProfileNames.containsKey(agentProfileId))
      return _agentProfileNames[agentProfileId]!;
    try {
      final res = await apiService.get('/api/agent-profiles/$agentProfileId');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data;
        String name = 'Agent Profile #$agentProfileId';
        if (data is Map<String, dynamic>) {
          name =
              (data['agent_name'] ?? data['owner_name'] ?? data['name'] ?? name)
                  .toString();
        } else if (data is String) {
          name = data;
        }
        _agentProfileNames[agentProfileId] = name;
        notifyListeners();
        return name;
      }
    } catch (_) {
      // ignore and fallback
    }
    final fallback = 'Agent Profile #$agentProfileId';
    _agentProfileNames[agentProfileId] = fallback;
    return fallback;
  }

  Future<void> fetchCashFlows({bool loadMore = false}) async {
    // Since API doesn't use pagination, we always fetch all data
    if (loadMore) return; // No load more functionality without pagination

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await apiService.get('/api/cash-flows');
      if (res.data != null && res.data['success'] == true) {
        final data = res.data['data'];
        if (data is Map && data.containsKey('cash_flows')) {
          // Handle paginated response format
          final cashFlows = data['cash_flows'];
          if (cashFlows is List) {
            items = cashFlows.map((e) => Map<String, dynamic>.from(e)).toList();
          } else {
            items = [];
          }
        } else if (data is List) {
          // Handle direct list response
          items = data.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          items = [];
        }
      } else {
        error = res.data?['message'] ?? 'Failed to fetch cash flows';
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String formatAmount(dynamic value) {
    if (value == null) return '-';
    try {
      if (value is num) return _formatInt(value.round());
      final asString = value.toString();
      final d = double.tryParse(asString);
      if (d != null) return _formatInt(d.round());
      final digits = asString.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return '-';
      return _formatInt(int.parse(digits));
    } catch (_) {
      return '-';
    }
  }

  String _formatInt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return 'Rp ${buf.toString()}';
  }

  Future<void> refresh() async {
    await fetchCashFlows(loadMore: false);
  }

  Future<bool> createCashFlow(Map<String, dynamic> cashFlowData) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await apiService.post('/api/cash-flows', data: cashFlowData);
      if (res.data != null && res.data['success'] == true) {
        // Refresh the list to include the new item
        await fetchCashFlows(loadMore: false);
        return true;
      } else {
        error = res.data?['message'] ?? 'Failed to create cash flow';
        return false;
      }
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

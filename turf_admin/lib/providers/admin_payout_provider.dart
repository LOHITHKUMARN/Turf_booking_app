import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';

class AdminPayoutProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _allPayouts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedStatus = 'all';

  List<dynamic> get allPayouts => _allPayouts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedStatus => _selectedStatus;

  List<dynamic> get filteredPayouts {
    return _allPayouts.where((payout) {
      final matchesStatus = _selectedStatus == 'all' || payout['status'] == _selectedStatus;
      final ownerName = payout['ownerId']?['name']?.toString().toLowerCase() ?? '';
      final matchesSearch = ownerName.contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  double get totalPendingAmount {
    return _allPayouts
        .where((p) => p['status'] == 'pending')
        .fold(0.0, (sum, p) => sum + (p['amount'] ?? 0).toDouble());
  }

  double get totalProcessedToday {
    final today = DateTime.now();
    return _allPayouts.where((p) {
      if (p['status'] != 'processed' || p['processedAt'] == null) return false;
      try {
        final processedDate = DateTime.parse(p['processedAt']);
        return processedDate.year == today.year &&
            processedDate.month == today.month &&
            processedDate.day == today.day;
      } catch (e) {
        return false;
      }
    }).fold(0.0, (sum, p) => sum + (p['amount'] ?? 0).toDouble());
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  Future<void> fetchAllPayouts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/admin/payouts');
      if (response.statusCode == 200) {
        _allPayouts = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching all payouts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePayoutStatus(String payoutId, String status) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/admin/payout/$payoutId/status',
        {'status': status},
      );
      if (response.statusCode == 200) {
        await fetchAllPayouts(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating payout status: $e');
      return false;
    }
  }
}

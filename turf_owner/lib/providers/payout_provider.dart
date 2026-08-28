import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';

class PayoutProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _walletData;
  List<dynamic> _payouts = [];
  bool _isLoading = false;

  Map<String, dynamic>? get walletData => _walletData;
  List<dynamic> get payouts => _payouts;
  bool get isLoading => _isLoading;

  Future<void> fetchWalletData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/owner/wallet');
      if (response.statusCode == 200) {
        _walletData = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching wallet data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayoutHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/owner/payouts');
      if (response.statusCode == 200) {
        _payouts = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching payout history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestPayout(double amount, Map<String, String> bankDetails) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/owner/payout/request',
        {
          'amount': amount,
          'bankDetails': bankDetails,
        },
      );
      if (response.statusCode == 201) {
        await fetchWalletData(); // Refresh balance
        await fetchPayoutHistory(); // Refresh history
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting payout: $e');
      return false;
    }
  }
}

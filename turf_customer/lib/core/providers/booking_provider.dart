import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../constants/api_constants.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _availableSlots = [];
  List<dynamic> _myBookings = [];
  bool _isLoading = false;

  List<dynamic> get availableSlots => _availableSlots;
  List<dynamic> get myBookings => _myBookings;
  bool get isLoading => _isLoading;

  BookingProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    SocketService().on('bookingUpdated', (data) {
      print('Socket: Booking updated, refreshing lists');
      fetchMyBookings();
    });
  }

  Future<void> fetchSlots(String turfId, DateTime date, {String? groundName}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      String url = '${ApiConstants.baseUrl}/customer/turfs/$turfId/slots?date=$dateStr';
      if (groundName != null && groundName.isNotEmpty) {
        url += '&groundName=${Uri.encodeComponent(groundName)}';
      }
      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        _availableSlots = jsonDecode(response.body);
      }
    } catch (e) {
      print('Fetch slots error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<dynamic> bookSlot({
    required String turfId,
    required String slotId,
    required DateTime date,
    required double amount,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/customer/bookings',
        {
          'turfId': turfId,
          'slotId': slotId,
          'bookingDate': DateFormat('yyyy-MM-dd').format(date),
          'totalAmount': amount,
          'paymentMethod': paymentMethod,
        },
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Booking error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyBookings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/customer/bookings');
      if (response.statusCode == 200) {
        _myBookings = jsonDecode(response.body);
      }
    } catch (e) {
      print('Fetch bookings error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markBookingAsReviewed(String bookingId, double rating, String comment) {
    bool updated = false;
    for (int i = 0; i < _myBookings.length; i++) {
      final b = _myBookings[i];
      if (b is Map && (b['id'] == bookingId || b['_id'] == bookingId)) {
        final updatedBooking = Map<String, dynamic>.from(b);
        final reviewObj = {
          'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          '_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'rating': rating,
          'comment': comment,
        };
        updatedBooking['reviewId'] = reviewObj;
        updatedBooking['review'] = reviewObj;
        _myBookings[i] = updatedBooking;
        updated = true;
        break;
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/customer/bookings/$bookingId/cancel',
        {},
      );
      if (response.statusCode == 200) {
        await fetchMyBookings(); // Refresh list after cancellation
        return true;
      }
      return false;
    } catch (e) {
      print('Cancel booking error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

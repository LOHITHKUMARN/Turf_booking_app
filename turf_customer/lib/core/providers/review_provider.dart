import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/review_model.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class ReviewProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Review> _turfReviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Review> get turfReviews => _turfReviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTurfReviews(String turfId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/reviews/turf/$turfId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _turfReviews = data.map((json) => Review.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReview({
    required String turfId,
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/reviews',
        {
          'turfId': turfId,
          'bookingId': bookingId,
          'rating': rating.round(),
          'comment': comment,
        },
      );

      if (response.statusCode == 201) {
        // Refresh reviews after adding
        await fetchTurfReviews(turfId);
        return true;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          _errorMessage = errorData['message'] ?? 'Failed to submit review';
        } catch (_) {
          _errorMessage = 'Failed to submit review';
        }
        return false;
      }
    } catch (e) {
      print('Error adding review: $e');
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

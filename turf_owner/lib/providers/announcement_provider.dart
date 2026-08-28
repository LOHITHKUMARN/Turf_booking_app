import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/announcement_model.dart';

class AnnouncementProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Announcement> _announcements = [];
  bool _isLoading = false;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/owner/announcements');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _announcements = data.map((json) => Announcement.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching announcements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAnnouncement({
    required String turfId,
    required String title,
    required String message,
    required String type,
    required bool isPublic,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/owner/announcement',
        {
          'turfId': turfId,
          'title': title,
          'message': message,
          'type': type,
          'isPublic': isPublic,
        },
      );
      if (response.statusCode == 201) {
        fetchAnnouncements(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating announcement: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAnnouncement(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.delete('${ApiConstants.baseUrl}/owner/announcement/$id');
      if (response.statusCode == 200) {
        _announcements.removeWhere((a) => a.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting announcement: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

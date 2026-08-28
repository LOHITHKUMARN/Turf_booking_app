import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/services/api_service.dart';
import '../core/services/socket_service.dart';
import '../core/constants/api_constants.dart';

class StaffProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<dynamic> _todayBookings = [];
  List<dynamic> _slots = [];
  Map<String, dynamic>? _stats;
  bool _isClockedIn = false;
  Map<String, dynamic>? _activeAttendance;
  List<dynamic> _announcements = [];

  bool get isLoading => _isLoading;
  List<dynamic> get todayBookings => _todayBookings;
  List<dynamic> get slots => _slots;
  Map<String, dynamic>? get stats => _stats;
  bool get isClockedIn => _isClockedIn;
  Map<String, dynamic>? get activeAttendance => _activeAttendance;
  List<dynamic> get announcements => _announcements;

  StaffProvider() {
    SocketService().on('bookingUpdated', (data) {
      print('Socket: Booking updated, refreshing staff bookings');
      fetchAssignedBookings();
    });
    SocketService().on('newAnnouncement', (data) {
      print('Socket: New announcement received, refreshing');
      fetchAnnouncements();
    });
  }

  Future<void> fetchSlots() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/staff/slots');
      if (response.statusCode == 200) {
        _slots = jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching slots: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleSlotBlock(String slotId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/staff/slot/$slotId/block',
        {},
      );
      if (response.statusCode == 200) {
        await fetchSlots();
        return true;
      }
      return false;
    } catch (e) {
      print('Error toggling slot block: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAssignedBookings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/staff/bookings');
      if (response.statusCode == 200) {
        _todayBookings = jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching assigned bookings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyBooking(String bookingId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/staff/verify/$bookingId',
        {},
      );
      if (response.statusCode == 200) {
        await fetchAssignedBookings();
        return true;
      }
      return false;
    } catch (e) {
      print('Error verifying booking: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBookingStatus(String bookingId, String status) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/staff/booking/$bookingId/status',
        {'status': status},
      );
      if (response.statusCode == 200) {
        await fetchAssignedBookings();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStats() async {
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/staff/stats');
      if (response.statusCode == 200) {
        _stats = json.decode(response.body);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> clockIn() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.post('${ApiConstants.baseUrl}/staff/attendance/clock-in', {});
      if (response.statusCode == 201) {
        _isClockedIn = true;
        _activeAttendance = json.decode(response.body);
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _errorMessage = data['message'] ?? 'Failed to clock in';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
      print('Error clocking in: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> clockOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.post('${ApiConstants.baseUrl}/staff/attendance/clock-out', {});
      if (response.statusCode == 200) {
        _isClockedIn = false;
        _activeAttendance = null;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _errorMessage = data['message'] ?? 'Failed to clock out';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
      print('Error clocking out: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActiveAttendance() async {
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/staff/attendance/active');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null) {
          _isClockedIn = true;
          _activeAttendance = data;
        } else {
          _isClockedIn = false;
          _activeAttendance = null;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching active attendance: $e');
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/upload'),
      );
      
      final token = await _apiService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> reportIssue({
    required String turfId,
    required String category,
    required String description,
    List<String>? images,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/staff/report-issue',
        {
          'turfId': turfId,
          'category': category,
          'description': description,
          'images': images ?? [],
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error reporting issue: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> createWalkInBooking({
    required String slotId,
    required String sport,
    required double totalAmount,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/staff/walk-in',
        {
          'slotId': slotId,
          'sport': sport,
          'totalAmount': totalAmount,
        },
      );
      if (response.statusCode == 201) {
        await fetchAssignedBookings();
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating walk-in booking: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTargetTurfStatus(String status) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/staff/turf/status',
        {'status': status},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating turf status: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addStaffNote(String bookingId, String notes) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/staff/booking/$bookingId/notes',
        {'notes': notes},
      );
      if (response.statusCode == 200) {
        await fetchAssignedBookings();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding staff note: $e');
      return false;
    }
  }

  Future<bool> reportIncident({
    required String turfId,
    required String type,
    required String severity,
    required String description,
    List<String>? images,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/staff/report-incident',
        {
          'turfId': turfId,
          'type': type,
          'severity': severity,
          'description': description,
          'images': images ?? [],
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error reporting incident: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnnouncements() async {
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/staff/announcements');
      if (response.statusCode == 200) {
        _announcements = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching announcements: $e');
    }
  }

  Future<bool> addExtraCharge({
    required String bookingId,
    required String type,
    required double amount,
    bool isPaid = false,
  }) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/staff/booking/$bookingId/extra-charges',
        {
          'type': type,
          'amount': amount,
          'isPaid': isPaid,
        },
      );
      if (response.statusCode == 200) {
        await fetchAssignedBookings();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding extra charge: $e');
      return false;
    }
  }

  /// Finds a booking by its short ID (last 6 characters) from the current todayBookings list.
  Map<String, dynamic>? findBookingByShortId(String shortId) {
    if (shortId.isEmpty) return null;
    
    final normalizedShortId = shortId.trim().toLowerCase();
    
    try {
      return _todayBookings.firstWhere(
        (booking) {
          final id = booking['_id'].toString();
          return id.toLowerCase().endsWith(normalizedShortId);
        },
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }
}

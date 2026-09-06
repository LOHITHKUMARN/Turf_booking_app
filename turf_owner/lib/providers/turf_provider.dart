import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/turf_model.dart';
import '../core/services/api_service.dart';
import '../core/services/socket_service.dart';
import '../core/constants/api_constants.dart';

class TurfProvider with ChangeNotifier {
  List<Turf> _turfs = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _maintenances = [];
  List<Map<String, dynamic>> _incidents = [];
  bool _isReportsLoading = false;

  List<Turf> get turfs => _turfs;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get maintenances => _maintenances;
  List<Map<String, dynamic>> get incidents => _incidents;
  bool get isReportsLoading => _isReportsLoading;

  TurfProvider() {
    SocketService().on('bookingUpdated', (data) {
      print('Socket: Booking updated event received by owner');
      // No-op: owner fetches bookings on demand from the bookings screen
      // But we can use this to trigger a local notification badge in future
    });
    SocketService().on('maintenanceUpdated', (data) {
      print('Socket: Maintenance updated received by owner');
      fetchOwnerReports();
    });
    SocketService().on('incidentUpdated', (data) {
      print('Socket: Incident updated received by owner');
      fetchOwnerReports();
    });
  }

  Future<void> fetchMyTurfs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get(ApiConstants.myTurfsUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _turfs = data.map((json) => Turf.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching turfs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTurf({
    required String name,
    required String city,
    required String area,
    required List<String> sports,
    required List<String> amenities,
    List<String> images = const [],
    List<String> grounds = const [],
    String upiId = '',
    double taxPercentage = 0.0,
    String turfType = 'both',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/owner/turf',
        {
          'name': name,
          'location': {'city': city, 'area': area},
          'sports': sports,
          'amenities': amenities,
          'images': images,
          'grounds': grounds,
          'upiId': upiId,
          'taxPercentage': taxPercentage,
          'turfType': turfType,
        },
      );

      if (response.statusCode == 201) {
        await fetchMyTurfs();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding turf: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadImage(String filePath) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.postMultipart(
        '${ApiConstants.baseUrl}/upload',
        filePath,
      );

      final respStr = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = jsonDecode(respStr);
        final url = data['url'];
        print('Image uploaded successfully: $url');
        return url;
      } else {
        print('Upload failed (${response.statusCode}): $respStr');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> uploadImages(List<String> filePaths) async {
    List<String> uploadedUrls = [];
    for (final path in filePaths) {
      final url = await uploadImage(path);
      if (url != null && url.isNotEmpty) {
        uploadedUrls.add(url);
      }
    }
    return uploadedUrls;
  }

  Future<List<dynamic>> fetchTurfSlots(String turfId) async {
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/owner/slots/$turfId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching slots: $e');
    }
    return [];
  }

  Future<bool> saveSlots(String turfId, List<Map<String, dynamic>> slots) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/owner/slots',
        {
          'turfId': turfId,
          'slots': slots,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error saving slots: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStaff({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/owner/staff',
        {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error creating staff: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> fetchBookings() async {
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/owner/bookings');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching bookings: $e');
    }
    return [];
  }

  List<dynamic> _staff = [];
  List<dynamic> get staff => _staff;

  Future<void> fetchStaff() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/owner/staff');
      if (response.statusCode == 200) {
        _staff = jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching staff: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignTurfToStaff(String staffId, String turfId, {String? groundName}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/owner/staff/$staffId/assign',
        {'turfId': turfId, 'groundName': groundName ?? ''},
      );
      if (response.statusCode == 200) {
        await fetchStaff();
        return true;
      }
      return false;
    } catch (e) {
      print('Error assigning turf to staff: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchStats() async {
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/owner/stats');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
    return null;
  }

  Future<bool> updateTurf({
    required String id,
    required String name,
    required String city,
    required String area,
    required List<String> sports,
    required List<String> amenities,
    List<String> images = const [],
    List<String> grounds = const [],
    String upiId = '',
    double taxPercentage = 0.0,
    String turfType = 'both',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/owner/turf/$id',
        {
          'name': name,
          'location': {'city': city, 'area': area},
          'sports': sports,
          'amenities': amenities,
          'images': images,
          'grounds': grounds,
          'upiId': upiId,
          'taxPercentage': taxPercentage,
          'turfType': turfType,
        },
      );

      if (response.statusCode == 200) {
        await fetchMyTurfs();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating turf: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTurfSettings(String turfId, Map<String, dynamic> settings) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/owner/turf/$turfId/settings',
        {'settings': settings},
      );

      if (response.statusCode == 200) {
        await fetchMyTurfs();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating turf settings: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestPayout(double amount, Map<String, String> bankDetails) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/owner/payout/request',
        {
          'amount': amount,
          'bankDetails': bankDetails,
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error requesting payout: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> fetchStaffAttendance({String? staffId, String? turfId}) async {
    try {
      String url = '${ApiConstants.baseUrl}/owner/staff/attendance';
      List<String> params = [];
      if (staffId != null) params.add('staffId=$staffId');
      if (turfId != null) params.add('turfId=$turfId');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching staff attendance: $e');
    }
    return [];
  }

  Future<bool> createManualBooking({
    required String turfId,
    required String slotId,
    required String sport,
    required double totalAmount,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/owner/manual-booking',
        {
          'turfId': turfId,
          'slotId': slotId,
          'sport': sport,
          'totalAmount': totalAmount,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error creating manual booking: $e');
      return false;
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
        '${ApiConstants.baseUrl}/owner/slot/$slotId/block',
        {},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling slot block: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOwnerReports() async {
    _isReportsLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(ApiConstants.ownerReportsUrl);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _maintenances = List<Map<String, dynamic>>.from(data['maintenances'] ?? []);
        _incidents = List<Map<String, dynamic>>.from(data['incidents'] ?? []);
      }
    } catch (e) {
      print('Error fetching owner reports: $e');
    } finally {
      _isReportsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMaintenanceStatus(String id, String status) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/owner/maintenance/$id/status',
        {'status': status},
      );
      if (response.statusCode == 200) {
        final idx = _maintenances.indexWhere((m) => (m['_id'] ?? m['id']).toString() == id);
        if (idx != -1) {
          _maintenances[idx]['status'] = status;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating maintenance status: $e');
      return false;
    }
  }

  Future<bool> updateIncidentStatus(String id, String status) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/owner/incident/$id/status',
        {'status': status},
      );
      if (response.statusCode == 200) {
        final idx = _incidents.indexWhere((inc) => (inc['_id'] ?? inc['id']).toString() == id);
        if (idx != -1) {
          _incidents[idx]['status'] = status;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating incident status: $e');
      return false;
    }
  }
}

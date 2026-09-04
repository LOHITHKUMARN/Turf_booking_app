import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../core/services/api_service.dart';
import '../core/services/socket_service.dart';
import '../core/services/notification_service.dart';
import '../core/constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('token') && !prefs.containsKey('refreshToken')) return;

      _token = prefs.getString('token');
      bool tokenExpired = _token == null;
      if (_token != null) {
        try {
          tokenExpired = JwtDecoder.isExpired(_token!);
        } catch (_) {
          tokenExpired = true;
        }
      }

      if (tokenExpired) {
        print('Staff AuthProvider: Token expired, attempting refresh...');
        final refreshed = await _apiService.refreshToken();
        if (refreshed) {
          _token = prefs.getString('token');
        } else {
          if (!prefs.containsKey('refreshToken')) {
            _token = null;
            _user = null;
            notifyListeners();
            return;
          }
        }
      }

      final userData = prefs.getString('userData');
      if (_token != null) {
        if (userData != null) {
          try {
            _user = jsonDecode(userData);
          } catch (e) {
            debugPrint('Staff error parsing userData: $e');
          }
        }
        
        if (_user == null) {
          try {
            _user = JwtDecoder.decode(_token!);
          } catch (e) {
            debugPrint('Staff error decoding token: $e');
          }
        }

        // Initialize Socket safely
        try {
          SocketService().init(token: _token!, userId: _user?['userId'] ?? _user?['id'] ?? '');
        } catch (e) {
          debugPrint('Staff Socket init error: $e');
        }
        
        // Register FCM Token safely
        try {
          await NotificationService().updateServerToken();
        } catch (e) {
          debugPrint('FCM Token refresh skipped: $e');
        }
      }
    } catch (e) {
      debugPrint('Staff tryAutoLogin error: $e');
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('Attempting login to: ${ApiConstants.baseUrl}/auth/login');

      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/auth/login',
        {'email': email, 'password': password},
      );

      print('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        
        final String role = (data['role'] ?? '').toString().trim().toLowerCase();
        
        if (role != 'staff') {
          print('Authorization REJECTED: Role is "$role", expected "staff"');
          _token = null;
          return 'Access denied: You are not registered as staff.';
        }

        _user = data;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        if (data['refreshToken'] != null) {
          await prefs.setString('refreshToken', data['refreshToken']);
        }
        await prefs.setString('userData', jsonEncode(data));

        // Initialize Socket
        SocketService().init(token: _token!, userId: _user?['userId'] ?? _user?['id'] ?? '');

        // Register FCM Token (Safe wrap to prevent login failure if Firebase not ready)
        try {
          await NotificationService().updateServerToken();
        } catch (e) {
          debugPrint('FCM Token registration skipped: $e');
        }

        notifyListeners();
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Login failed. Please check your credentials.';
      }
    } catch (e) {
      print('Login error: $e');
      return 'Connection error. Please check your internet.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    SocketService().disconnect();
    notifyListeners();
  }
}

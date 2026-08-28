import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../core/services/api_service.dart';
import '../core/services/socket_service.dart';
import '../core/services/notification_service.dart';
import '../core/constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConstants.loginUrl,
        {
          'identifier': identifier,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['role'] != 'admin') {
          _isLoading = false;
          notifyListeners();
          return false;
        }
        _user = User.fromJson(data);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        if (data['refreshToken'] != null) {
          await prefs.setString('refreshToken', data['refreshToken']);
        }
        await prefs.setString('userData', jsonEncode(data));
        
        // Initialize Socket
        SocketService().init(token: data['token'], userId: data['_id'] ?? '');

        // Register FCM Token
        NotificationService().updateServerToken();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'admin',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConstants.signupUrl,
        {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _user = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        if (data['refreshToken'] != null) {
          await prefs.setString('refreshToken', data['refreshToken']);
        }
        await prefs.setString('userData', jsonEncode(data));

        // Initialize Socket
        SocketService().init(token: data['token'], userId: data['_id'] ?? '');

        // Register FCM Token
        NotificationService().updateServerToken();

        _isLoading = false;
        notifyListeners();
        return {'success': true};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': data['message'] ?? 'Signup failed'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    await prefs.remove('userData');
    SocketService().disconnect();
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    final userData = prefs.getString('userData');
    if (userData != null) {
      final data = jsonDecode(userData);
      if (data['role'] == 'admin') {
        _user = User.fromJson(data);
        
        // Initialize Socket
        SocketService().init(
          token: prefs.getString('token') ?? '', 
          userId: _user?.id ?? ''
        );
        
        // Register FCM Token
        NotificationService().updateServerToken();
        
        notifyListeners();
      } else {
        await prefs.remove('token');
        await prefs.remove('refreshToken');
        await prefs.remove('userData');
        _user = null;
        notifyListeners();
      }
    }
  }
}

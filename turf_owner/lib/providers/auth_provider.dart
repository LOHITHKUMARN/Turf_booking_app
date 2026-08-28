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

  Future<String?> login(String identifier, String password) async {
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
        
        // Safety check: Ensure only owners (or admin) can log into owner app
        if (data['role'] != 'owner' && data['role'] != 'admin') {
          _isLoading = false;
          notifyListeners();
          return 'Access denied: You are not registered as an owner.'; 
        }

        _user = User.fromJson(data);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _user!.token!);
        if (data['refreshToken'] != null) {
          await prefs.setString('refreshToken', data['refreshToken']);
        }
        await prefs.setString('userData', jsonEncode(data));

        // Initialize Socket
        SocketService().init(token: _user!.token!, userId: _user!.id ?? '');
        
        // Register FCM Token
        NotificationService().updateServerToken();
        
        _isLoading = false;
        notifyListeners();
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return data['message'] ?? 'Login failed. Please check your credentials.';
      }
    } catch (e) {
      print('DEBUG: AuthProvider.login EXCEPTION: $e');
      _isLoading = false;
      notifyListeners();
      return 'Connection error. Please check your internet.';
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
      _user = User.fromJson(jsonDecode(userData));
      
      // Initialize Socket
      if (_user?.token != null) {
        SocketService().init(token: _user!.token!, userId: _user!.id ?? '');
        
        // Register FCM Token
        NotificationService().updateServerToken();
      }
      
      notifyListeners();
    }
  }
}

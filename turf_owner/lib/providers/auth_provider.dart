import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
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
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('token') && !prefs.containsKey('refreshToken')) return;

      String? token = prefs.getString('token');
      bool tokenExpired = token == null;
      if (token != null) {
        try {
          tokenExpired = JwtDecoder.isExpired(token);
        } catch (_) {
          tokenExpired = true;
        }
      }

      if (tokenExpired) {
        print('Owner AuthProvider: Token expired, attempting refresh...');
        final refreshed = await _apiService.refreshToken();
        if (refreshed) {
          token = prefs.getString('token');
        } else {
          if (!prefs.containsKey('refreshToken')) {
            _user = null;
            notifyListeners();
            return;
          }
        }
      }

      final userData = prefs.getString('userData');
      if (userData != null) {
        try {
          final data = jsonDecode(userData);
          _user = User.fromJson(data);
        } catch (e) {
          debugPrint('Owner error parsing userData: $e');
        }
      }

      if (_user == null && token != null) {
        try {
          final decoded = JwtDecoder.decode(token);
          _user = User(
            id: (decoded['userId'] ?? '').toString(),
            name: 'Owner',
            email: '',
            phone: '',
            role: (decoded['role'] ?? 'owner').toString(),
            status: 'active',
            token: token,
          );
        } catch (e) {
          debugPrint('Owner fallback decoding token: $e');
        }
      } else if (_user != null && token != null) {
        _user = User(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          phone: _user!.phone,
          role: _user!.role,
          status: _user!.status,
          token: token,
        );
      }

      if (_user != null) {
        try {
          final activeToken = token ?? _user?.token;
          if (activeToken != null) {
            SocketService().init(token: activeToken, userId: _user!.id);
            NotificationService().updateServerToken();
          }
        } catch (e) {
          debugPrint('Owner Socket/FCM init error: $e');
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Owner tryAutoLogin error: $e');
    }
  }
}

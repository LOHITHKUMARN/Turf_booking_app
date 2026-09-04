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
        print('Admin AuthProvider: Token expired, attempting refresh...');
        final refreshed = await _apiService.refreshToken();
        if (refreshed) {
          token = prefs.getString('token');
        } else {
          // If refresh token is missing or explicitly invalid, exit
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
          debugPrint('Error parsing userData: $e');
        }
      }
      
      if (_user == null && token != null) {
        try {
          final decoded = JwtDecoder.decode(token);
          _user = User(
            id: (decoded['userId'] ?? '').toString(),
            name: 'Admin',
            email: '',
            phone: '',
            role: (decoded['role'] ?? 'admin').toString(),
            status: 'active',
            token: token,
          );
        } catch (e) {
          debugPrint('Error fallback decoding token: $e');
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
          SocketService().init(
            token: token ?? prefs.getString('token') ?? '', 
            userId: _user!.id
          );
        } catch (e) {
          debugPrint('Admin Socket init error: $e');
        }
        
        try {
          NotificationService().updateServerToken();
        } catch (e) {
          debugPrint('Admin FCM init error: $e');
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Admin tryAutoLogin error: $e');
    }
  }
}

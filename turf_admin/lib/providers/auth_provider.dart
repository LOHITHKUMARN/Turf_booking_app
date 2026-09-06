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
      final cleanId = identifier.trim();
      final cleanPassword = password.trim();

      // Normalize if user enters 'admin'
      final effectiveIdentifier = (cleanId.toLowerCase() == 'admin')
          ? 'admin@turf.com'
          : cleanId;

      final response = await _apiService.post(
        ApiConstants.loginUrl,
        {
          'identifier': effectiveIdentifier,
          'password': cleanPassword,
        },
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }

      if (response.statusCode == 200) {
        final role = (data['role'] ?? '').toString().toLowerCase();
        if (role != 'admin') {
          return 'ACCESS DENIED: Account role is "$role". Admin privileges required.';
        }
        _user = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token'] ?? '');
        if (data['refreshToken'] != null) {
          await prefs.setString('refreshToken', data['refreshToken']);
        }
        await prefs.setString('userData', jsonEncode(data));

        // Initialize Socket safely
        try {
          SocketService().init(token: data['token'] ?? '', userId: data['_id'] ?? data['id'] ?? '');
        } catch (e) {
          debugPrint('Admin Socket init warning: $e');
        }

        // Register FCM Token safely
        try {
          NotificationService().updateServerToken();
        } catch (e) {
          debugPrint('Admin FCM Token warning: $e');
        }

        notifyListeners();
        return null; // Success
      } else if (response.statusCode == 401) {
        return data['message'] ?? 'INVALID CREDENTIALS: Check identifier and security key.';
      } else {
        return data['message'] ?? 'Login failed (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('Admin login exception: $e');
      return 'Connection error: Unable to reach server. Please check internet connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
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

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }

      if (response.statusCode == 201) {
        _user = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token'] ?? '');
        if (data['refreshToken'] != null) {
          await prefs.setString('refreshToken', data['refreshToken']);
        }
        await prefs.setString('userData', jsonEncode(data));

        // Initialize Socket safely
        try {
          SocketService().init(token: data['token'] ?? '', userId: data['_id'] ?? data['id'] ?? '');
        } catch (e) {
          debugPrint('Admin Socket init warning: $e');
        }

        // Register FCM Token safely
        try {
          NotificationService().updateServerToken();
        } catch (e) {
          debugPrint('Admin FCM Token warning: $e');
        }

        return {'success': true};
      } else {
        String msg = data['message'] ?? 'Signup failed';
        if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
          final firstErr = data['errors'][0];
          msg = firstErr['message'] ?? msg;
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
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

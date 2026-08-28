import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';
import '../constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;

  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/auth/login',
        {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        
        // Check role
        final decodedToken = JwtDecoder.decode(token);
        if (decodedToken['role'] != 'customer') {
           return 'Access denied: You are not registered as a customer.';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        if (data['refreshToken'] != null) {
          await prefs.setString('refreshToken', data['refreshToken']);
        }
        _user = data;
        await fetchProfile(); // Fetch full user details after login
        
        // Initialize Socket
        SocketService().init(token: token, userId: _user?['_id'] ?? '');
        
        // Register FCM Token
        NotificationService().updateServerToken();
        
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

  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}/auth/signup',
        {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': 'customer',
        },
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        if (data['refreshToken'] != null) {
          await prefs.setString('refreshToken', data['refreshToken']);
        }
        _user = data; // Backend returns the user fields at top level
        await fetchProfile(); // Fetch full profile to be safe
        
        // Initialize Socket
        SocketService().init(token: token, userId: _user?['_id'] ?? '');
        
        // Register FCM Token
        NotificationService().updateServerToken();
        
        return true;
      }
      return false;
    } catch (e) {
      print('Signup error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    _user = null;
    SocketService().disconnect();
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    final token = prefs.getString('token')!;
    if (JwtDecoder.isExpired(token)) {
      await prefs.remove('token');
      return;
    }

    try {
      final decodedToken = JwtDecoder.decode(token);
      if (decodedToken['role'] == 'customer') {
          _user = {
            'userId': decodedToken['userId'],
            'role': decodedToken['role'],
            'name': 'User', 
          };
          await fetchProfile(); // Fetch full profile to get name, phone, image etc.
          
          // Initialize Socket
          SocketService().init(token: token, userId: _user?['_id'] ?? decodedToken['userId'] ?? '');

          // Register FCM Token
          NotificationService().updateServerToken();
      }
    } catch (e) {
      print('Auto login error: $e');
    }
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('${ApiConstants.baseUrl}/customer/profile');
      print('AuthProvider: fetchProfile status ${response.statusCode}');
      if (response.statusCode == 200) {
        _profile = jsonDecode(response.body);
        print('AuthProvider: Profile fetched for ${_profile?['name']}');
        // Merge profile data into user for consistency
        _user = {
          ...?_user,
          ...?_profile,
        };
      } else {
        print('AuthProvider: fetchProfile failed ${response.body}');
      }
    } catch (e) {
      print('Fetch profile error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.put(
        '${ApiConstants.baseUrl}/customer/profile',
        data,
      );
      if (response.statusCode == 200) {
        _profile = jsonDecode(response.body);
        _user = {
          ...?_user,
          ...?_profile,
        };
        return true;
      }
      return false;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadImage(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/upload'),
      );
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Prepend host if it's a relative path
        String path = data['url'];
        if (path.startsWith('/')) {
           final base = ApiConstants.baseUrl.replaceAll('/api', '');
           return '$base$path';
        }
        return path;
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../constants/api_constants.dart';

class ApiService {
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final token = includeAuth ? await getToken() : null;
    return {
      'Content-Type': 'application/json',
      'bypass-tunnel-reminder': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedRefreshToken = prefs.getString('refreshToken');
      if (storedRefreshToken == null) return false;

      print('ApiService: Attempting to refresh token...');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'requestToken': storedRefreshToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('token', data['accessToken']);
        if (data['refreshToken'] != null) {
          await prefs.setString('refreshToken', data['refreshToken']);
        }
        print('ApiService: Token refreshed successfully');
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('ApiService: Refresh token rejected (${response.statusCode})');
        await prefs.remove('token');
        await prefs.remove('refreshToken');
        await prefs.remove('userData');
        return false;
      } else {
        print('ApiService: Refresh failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('ApiService: Refresh error: $e');
      return false;
    }
  }

  Future<http.Response> post(String url, Map<String, dynamic> body) async {
    final isAuthEndpoint = url.contains('/auth/login') ||
        url.contains('/auth/signup') ||
        url.contains('/auth/refresh');
    Map<String, String> headers = await _getHeaders(includeAuth: !isAuthEndpoint);
    http.Response response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 401 && !isAuthEndpoint) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 30));
      }
    }
    return response;
  }

  Future<http.Response> get(String url) async {
    Map<String, String> headers = await _getHeaders();
    http.Response response = await http.get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await http.get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 30));
      }
    }
    return response;
  }

  Future<http.Response> put(String url, Map<String, dynamic> body) async {
    Map<String, String> headers = await _getHeaders();
    http.Response response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await http.put(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 30));
      }
    }
    return response;
  }

  Future<http.Response> delete(String url) async {
    Map<String, String> headers = await _getHeaders();
    http.Response response = await http.delete(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await http.delete(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 30));
      }
    }
    return response;
  }
}

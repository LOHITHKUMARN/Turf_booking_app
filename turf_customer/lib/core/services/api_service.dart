import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    print('ApiService: Getting headers...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print('ApiService: Prefs obtained, token: ${token != null}');
      return {
        'Content-Type': 'application/json',
        'bypass-tunnel-reminder': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('ApiService: Error getting headers: $e');
      return {'Content-Type': 'application/json'};
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken');
      if (refreshToken == null) return false;

      print('ApiService: Attempting to refresh token...');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'requestToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('token', data['accessToken']);
        print('ApiService: Token refreshed successfully');
        return true;
      } else {
        print('ApiService: Refresh failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('ApiService: Refresh error: $e');
      return false;
    }
  }

  Future<http.Response> get(String url) async {
    print('ApiService GET: $url');
    Map<String, String> headers = await _getHeaders();
    http.Response response = await http.get(Uri.parse(url), headers: headers);
    
    if (response.statusCode == 401) {
      bool refreshed = await _refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await http.get(Uri.parse(url), headers: headers);
      }
    }
    
    print('ApiService GET Response [${response.statusCode}]: ${response.body.length > 100 ? response.body.substring(0, 100) : response.body}');
    return response;
  }

  Future<http.Response> post(String url, Map<String, dynamic> body) async {
    print('ApiService POST: $url');
    print('ApiService Body: ${jsonEncode(body)}');
    Map<String, String> headers = await _getHeaders();
    print('ApiService: Sending request...');
    try {
      http.Response response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        bool refreshed = await _refreshToken();
        if (refreshed) {
          headers = await _getHeaders();
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 15));
        }
      }

      print('ApiService Response Code: ${response.statusCode}');
      return response;
    } catch (e) {
      print('ApiService Error: $e');
      rethrow;
    }
  }


  Future<http.Response> put(String url, Map<String, dynamic> body) async {
    Map<String, String> headers = await _getHeaders();
    http.Response response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      bool refreshed = await _refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await http.put(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        );
      }
    }

    return response;
  }

  Future<http.Response> delete(String url) async {
    Map<String, String> headers = await _getHeaders();
    http.Response response = await http.delete(Uri.parse(url), headers: headers);

    if (response.statusCode == 401) {
      bool refreshed = await _refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await http.delete(Uri.parse(url), headers: headers);
      }
    }

    return response;
  }
}

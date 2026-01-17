import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL for the API (includes /api prefix for Render deployment)
  static const String baseUrl = "https://datapirates.onrender.com/api";

  // Helper to get stored token and format for Node.js cookie middleware
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {"Content-Type": "application/json", "Cookie": "token=$token"};
  }

  // Registration API
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    int? age,
    String? gender,
    double? height,
    double? weight,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "age": age,
          "gender": gender?.toLowerCase(),
          "height": height,
          "weight": weight,
        }),
      );
      final decodedResponse = jsonDecode(response.body);
      if (response.statusCode == 201) {
        // Save token if returned in Set-Cookie
        _saveCookie(response);
        return {"success": true, "data": decodedResponse};
      } else {
        return {
          "success": false,
          "message": decodedResponse['message'] ?? "Registration failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // Login API
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      final decodedResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _saveCookie(response);
        return {"success": true, "data": decodedResponse};
      } else {
        return {
          "success": false,
          "message": decodedResponse['message'] ?? "Login failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // Helper to save cookie token to shared preferences
  static void _saveCookie(http.Response response) async {
    final String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      final prefs = await SharedPreferences.getInstance();
      final token = rawCookie.split(';')[0].split('=')[1];
      await prefs.setString('token', token);
    }
  }

  // New Method: Fetch Dashboard Health Data
  static Future<Map<String, dynamic>> getHealthData(String date) async {
    // Corrected path to /health/day/:date based on server.js routes
    final url = Uri.parse('$baseUrl/health/day/$date');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cache offline
        await _cacheData('health_data_$date', data);
        return {"success": true, "data": data};
      } else if (response.statusCode == 404) {
        return {"success": true, "data": null};
      } else {
        return {"success": false, "message": "Failed to fetch health data"};
      }
    } catch (e) {
      // Try to load from cache
      final cachedData = await _getCachedData('health_data_$date');
      if (cachedData != null) {
        return {"success": true, "data": cachedData, "cached": true};
      }
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // Get Weekly Analytics
  static Future<Map<String, dynamic>> getWeeklyAnalytics() async {
    final url = Uri.parse('$baseUrl/analytics/weekly');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cache offline
        await _cacheData('weekly_analytics', data);
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": "Failed to fetch weekly analytics",
        };
      }
    } catch (e) {
      // Try to load from cache
      final cachedData = await _getCachedData('weekly_analytics');
      if (cachedData != null) {
        return {"success": true, "data": cachedData, "cached": true};
      }
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // Get Monthly Analytics
  static Future<Map<String, dynamic>> getMonthlyAnalytics() async {
    final url = Uri.parse('$baseUrl/analytics/monthly');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cache offline
        await _cacheData('monthly_analytics', data);
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": "Failed to fetch monthly analytics",
        };
      }
    } catch (e) {
      // Try to load from cache
      final cachedData = await _getCachedData('monthly_analytics');
      if (cachedData != null) {
        return {"success": true, "data": cachedData, "cached": true};
      }
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userName');
  }

  // Get User Profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    final url = Uri.parse('$baseUrl/auth/profile');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cache offline
        await _cacheData('user_profile', data);
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": "Failed to fetch profile"};
      }
    } catch (e) {
      // Try to load from cache
      final cachedData = await _getCachedData('user_profile');
      if (cachedData != null) {
        return {"success": true, "data": cachedData, "cached": true};
      }
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // Update User Profile
  static Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? mobile,
  }) async {
    final url = Uri.parse('$baseUrl/auth/profile');
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (age != null) body['age'] = age;
      if (gender != null) body['gender'] = gender;
      if (height != null) body['height'] = height;
      if (weight != null) body['weight'] = weight;
      if (mobile != null) body['mobile'] = mobile;

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Update cache
        await _cacheData('user_profile', data['user']);
        return {"success": true, "data": data};
      } else {
        final errorBody = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorBody['message'] ?? "Failed to update profile",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // Get AI Summary
  static Future<Map<String, dynamic>> getAISummary({
    int retryCount = 0,
    bool forceRefresh = false,
  }) async {
    // Clear cache if forcing refresh
    if (forceRefresh && retryCount == 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_ai_summary');
      await prefs.remove('cache_ai_summary_timestamp');
    }

    final url = Uri.parse('$baseUrl/ai/summary');
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(url, headers: headers)
          .timeout(
            const Duration(seconds: 60), // Increased timeout for AI generation
            onTimeout: () {
              throw Exception(
                'Request timeout - server took too long to respond',
              );
            },
          );

      print('AI Summary Response Status: ${response.statusCode}');
      print('AI Summary Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cache offline
        await _cacheData('ai_summary', data);
        return {"success": true, "data": data};
      } else if (response.statusCode == 500 && retryCount < 2) {
        // Retry on server error (AI might be warming up)
        print('Retrying AI Summary... attempt ${retryCount + 2}');
        await Future.delayed(const Duration(seconds: 2));
        return getAISummary(retryCount: retryCount + 1, forceRefresh: false);
      } else {
        // Try to return cached data on error (only if not forcing refresh)
        if (!forceRefresh) {
          final cachedData = await _getCachedData('ai_summary');
          if (cachedData != null) {
            return {"success": true, "data": cachedData, "cached": true};
          }
        }
        final errorBody = jsonDecode(response.body);
        return {
          "success": false,
          "message":
              errorBody['error'] ??
              "Failed to fetch AI summary (${response.statusCode})",
        };
      }
    } catch (e) {
      print('AI Summary Error: $e');

      // Retry on connection errors
      if (retryCount < 2) {
        print('Retrying AI Summary after error... attempt ${retryCount + 2}');
        await Future.delayed(const Duration(seconds: 2));
        return getAISummary(retryCount: retryCount + 1, forceRefresh: false);
      }

      // Try to load from cache (only if not forcing refresh)
      if (!forceRefresh) {
        final cachedData = await _getCachedData('ai_summary');
        if (cachedData != null) {
          return {"success": true, "data": cachedData, "cached": true};
        }
      }
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // Cache data offline
  static Future<void> _cacheData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$key', jsonEncode(data));
    await prefs.setString(
      'cache_${key}_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  // Get cached data
  static Future<dynamic> _getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString('cache_$key');
    if (cachedString != null) {
      return jsonDecode(cachedString);
    }
    return null;
  }

  // Get Health History
  static Future<Map<String, dynamic>> getHealthHistory({int days = 30}) async {
    final url = Uri.parse('$baseUrl/history?days=$days');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cache offline
        await _cacheData('health_history_$days', data);
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": "Failed to fetch health history"};
      }
    } catch (e) {
      // Try to load from cache
      final cachedData = await _getCachedData('health_history_$days');
      if (cachedData != null) {
        return {"success": true, "data": cachedData, "cached": true};
      }
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // Sync Strava Activities - pulls latest data from Strava
  static Future<Map<String, dynamic>> syncStravaActivities() async {
    final url = Uri.parse('$baseUrl/strava/sync');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "data": data};
      } else {
        final error = jsonDecode(response.body);
        return {
          "success": false,
          "message": error['message'] ?? "Failed to sync Strava",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}

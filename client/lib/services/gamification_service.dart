import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GamificationService {
  static const String baseUrl = "https://datapirates.onrender.com/api";

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {"Content-Type": "application/json", "Cookie": "token=$token"};
  }

  /// Get user's gamification profile (points, level, badges)
  static Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$baseUrl/gamification/profile');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": decoded};
      } else {
        return {
          "success": false,
          "message": decoded['message'] ?? "Failed to fetch profile",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Sync daily gamification points
  static Future<Map<String, dynamic>> syncGamification() async {
    final url = Uri.parse('$baseUrl/gamification/sync');
    try {
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": decoded};
      } else {
        return {
          "success": false,
          "message": decoded['message'] ?? "Sync failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Get today's leaderboard
  static Future<Map<String, dynamic>> getTodayLeaderboard() async {
    final url = Uri.parse('$baseUrl/gamification/leaderboard/today');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": decoded};
      } else {
        return {
          "success": false,
          "message": decoded['message'] ?? "Failed to fetch leaderboard",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Reset gamification (for testing)
  static Future<Map<String, dynamic>> resetGamification() async {
    final url = Uri.parse('$baseUrl/gamification/reset');
    try {
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": decoded};
      } else {
        return {
          "success": false,
          "message": decoded['message'] ?? "Reset failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}

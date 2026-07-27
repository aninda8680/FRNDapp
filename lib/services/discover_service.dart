import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart'; // To get the cookie token

class DiscoverService {
  static const String baseUrl = 'https://frnd-api-n3hv.onrender.com/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AuthService.token != null) 'cookie': AuthService.token!,
      };

  /// Fetch the discover feed profiles
  static Future<List<Map<String, dynamic>>> getFeed({int page = 1, int limit = 15}) async {
    try {
      final url = Uri.parse('$baseUrl/discover?page=$page&limit=$limit');
      print('Fetching discover feed from: $url');
      print('Headers being sent: $_headers');
      
      final response = await http.get(url, headers: _headers);
      print('Discover API Status Code: ${response.statusCode}');
      print('Discover API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['profiles'] != null) {
          final List<dynamic> profiles = data['profiles'];
          return profiles.map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return []; // Return empty list instead of mocks if unauthorized or empty
    } catch (e) {
      print('Error fetching discover feed: $e');
      return [];
    }
  }

  /// Like a profile. Returns response map (e.g. {matchFormed: true, conversationId: '...'})
  static Future<Map<String, dynamic>?> likeProfile(String targetId) async {
    try {
      final url = Uri.parse('$baseUrl/like/$targetId');
      final response = await http.post(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error liking profile: $e');
      return null;
    }
  }

  /// Superlike a profile. Returns response map
  static Future<Map<String, dynamic>?> superlikeProfile(String targetId) async {
    try {
      final url = Uri.parse('$baseUrl/superlike/$targetId');
      final response = await http.post(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error superliking profile: $e');
      return null;
    }
  }

  /// Pass / Dislike a profile
  static Future<bool> passProfile(String targetId) async {
    try {
      final url = Uri.parse('$baseUrl/pass/$targetId');
      final response = await http.post(url, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      print('Error passing profile: $e');
      return false;
    }
  }
}

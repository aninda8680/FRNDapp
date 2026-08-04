import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class MatchesService {
  static const String baseUrl = 'https://frnd-api-n3hv.onrender.com/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AuthService.token != null) 'cookie': AuthService.token!,
      };

  /// Fetch all mutual matches for the authenticated user
  static Future<List<Map<String, dynamic>>> getMatches() async {
    try {
      final url = Uri.parse('$baseUrl/matches');
      print('Fetching matches from: $url');
      
      final response = await http.get(url, headers: _headers);
      print('Matches API Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['matches'] != null) {
          final List<dynamic> matches = data['matches'];
          return matches.map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching matches: $e');
      return [];
    }
  }

  /// Fetch incoming likes
  static Future<Map<String, dynamic>> getIncomingLikes() async {
    try {
      final url = Uri.parse('$baseUrl/likes/received');
      print('Fetching incoming likes from: $url');
      final response = await http.get(url, headers: _headers);
      print('Incoming Likes API Status: ${response.statusCode}');
      print('Incoming Likes API Body: ${response.body}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching incoming likes: $e');
      return {};
    }
  }

  /// Like a user back (POST /api/like/:senderId).
  /// Returns response map e.g. { "success": true, "matchFormed": true, "conversationId": "..." }
  static Future<Map<String, dynamic>?> likeUser(String targetId) async {
    try {
      final url = Uri.parse('$baseUrl/like/$targetId');
      print('Liking user at: $url');
      final response = await http.post(url, headers: _headers);
      print('Like API Status Code: ${response.statusCode}');
      print('Like API Body: ${response.body}');
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error liking user: $e');
      return null;
    }
  }
}


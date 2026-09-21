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
  static Future<List<Map<String, dynamic>>> getFeed({int limit = 10, List<String> excludeIds = const []}) async {
    try {
      final queryParams = ['limit=$limit'];
      if (excludeIds.isNotEmpty) {
        queryParams.add('excludeIds=${excludeIds.join(',')}');
      }
      
      final url = Uri.parse('$baseUrl/discover?${queryParams.join('&')}');
      print('Fetching discover feed from: $url');
      print('Headers being sent: $_headers');
      
      final response = await http.get(url, headers: _headers);
      print('Discover API Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['limitReached'] == true) {
          throw Exception('DAILY_LIMIT_REACHED');
        }

        if (data['profiles'] != null) {
          final List<dynamic> profiles = data['profiles'];
          return profiles.map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return []; 
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
      } else if (response.statusCode == 403 || response.statusCode == 429) {
        final data = json.decode(response.body);
        throw Exception('QUOTA_EXCEEDED: ${data['message'] ?? 'Daily limit reached'}');
      }
      return null;
    } catch (e) {
      print('Error liking profile: $e');
      if (e.toString().contains('QUOTA_EXCEEDED')) rethrow;
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
      } else if (response.statusCode == 403 || response.statusCode == 429) {
        final data = json.decode(response.body);
        throw Exception('QUOTA_EXCEEDED: ${data['message'] ?? 'Daily limit reached'}');
      }
      return null;
    } catch (e) {
      print('Error superliking profile: $e');
      if (e.toString().contains('QUOTA_EXCEEDED')) rethrow;
      return null;
    }
  }

  /// Pass / Dislike a profile
  static Future<bool> passProfile(String targetId) async {
    try {
      final url = Uri.parse('$baseUrl/pass/$targetId');
      final response = await http.post(url, headers: _headers);
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403 || response.statusCode == 429) {
        final data = json.decode(response.body);
        throw Exception('QUOTA_EXCEEDED: ${data['message'] ?? 'Daily limit reached'}');
      }
      return false;
    } catch (e) {
      print('Error passing profile: $e');
      if (e.toString().contains('QUOTA_EXCEEDED')) rethrow;
      return false;
    }
  }
}

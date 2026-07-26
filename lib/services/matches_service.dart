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
}

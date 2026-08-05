import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/announcement.dart';
import 'auth_service.dart';

class AnnouncementService {
  static const String baseUrl = 'https://frnd-api-n3hv.onrender.com/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AuthService.token != null) 'cookie': AuthService.token!,
      };

  /// Fetches system announcements from the backend.
  static Future<List<Announcement>> getAnnouncements() async {
    try {
      final url = Uri.parse('$baseUrl/announcements');
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> announcementsData = data['announcements'] ?? [];
        
        return announcementsData
            .map((json) => Announcement.fromJson(json))
            .toList();
      } else {
        print('Failed to fetch announcements: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }
}

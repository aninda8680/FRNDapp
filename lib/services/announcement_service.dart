import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
        print('==== DEBUG Announcements API Response: $data ====');
        final List<dynamic> announcementsData = data['announcements'] ?? [];
        
        return announcementsData
            .map((json) => Announcement.fromJson(json))
            .toList();
      } else {
        print('==== DEBUG Failed to fetch announcements: ${response.statusCode} - ${response.body} ====');
        return [];
      }
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  static const String _readAnnouncementsKey = 'read_announcements_ids';

  /// Returns the number of unread announcements.
  static Future<int> getUnreadCount() async {
    final announcements = await getAnnouncements();
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readAnnouncementsKey) ?? [];
    
    int unreadCount = 0;
    for (var announcement in announcements) {
      if (!readIds.contains(announcement.id)) {
        unreadCount++;
      }
    }
    return unreadCount;
  }

  /// Marks the given announcements as read.
  static Future<void> markAllAsRead(List<Announcement> announcements) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readAnnouncementsKey) ?? [];
    
    bool updated = false;
    for (var announcement in announcements) {
      if (!readIds.contains(announcement.id)) {
        readIds.add(announcement.id);
        updated = true;
      }
    }
    
    if (updated) {
      await prefs.setStringList(_readAnnouncementsKey, readIds);
    }
  }
}

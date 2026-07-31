import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/dev_config.dart';

class OnboardingService {
  static const String baseUrl = 'https://frnd-api-n3hv.onrender.com/api';

  static Future<Map<String, dynamic>?> fetchConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/config/onboarding'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      print('[OnboardingService] Failed to fetch config: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('[OnboardingService] Error fetching config: $e');
      return null;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/dev_config.dart';

class OnboardingService {
  static const String baseUrl = 'https://frnd-api-n3hv.onrender.com/api';

  static Future<Map<String, dynamic>?> fetchConfig() async {
    if (DevConfig.bypassAuth) {
      return {
        "segments": [
          {
            "id": "sports_fitness",
            "name": "Sports & Fitness",
            "interests": [
              { "id": "football", "label": "Football", "emoji": "⚽" },
              { "id": "cricket", "label": "Cricket", "emoji": "🏏" }
            ]
          },
          {
            "id": "gaming_tech",
            "name": "Gaming & Tech",
            "interests": [
              { "id": "coding", "label": "Coding / Programming", "emoji": "💻" },
              { "id": "gaming", "label": "Gaming", "emoji": "🎮" }
            ]
          }
        ],
        "sections": [
          {
            "id": "questions",
            "name": "Questions",
            "description": "A direct question the user answers in their own words.",
            "prompts": [
              { "id": "q01", "text": "What's a random skill you're weirdly proud of?" },
              { "id": "q02", "text": "A random fact I love is..." }
            ]
          }
        ]
      };
    }

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

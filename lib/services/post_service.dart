import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PostService {
  static const String baseUrl = 'https://frnd-api-n3hv.onrender.com/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AuthService.token != null) 'cookie': AuthService.token!,
      };

  /// Fetch posts feed (anonymous + public), last 24 hours
  static Future<List<Map<String, dynamic>>> getPosts(
      {int page = 1, int limit = 20}) async {
    try {
      final url = Uri.parse('$baseUrl/posts?page=$page&limit=$limit');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['posts'] != null) {
          final List<dynamic> posts = data['posts'];
          return posts.map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      return [];
    }
  }

  /// Create a new post.
  /// [isAnonymous] — when true author identity is hidden (default true per API).
  static Future<Map<String, dynamic>?> createPost(
    String content, {
    bool isAnonymous = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/posts');
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode({
          'content': content,
          'isAnonymous': isAnonymous,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  /// Toggle upvote on a post. Returns updated vote counts or null on failure.
  static Future<Map<String, dynamic>?> upvotePost(String postId) async {
    try {
      final url = Uri.parse('$baseUrl/posts/$postId/upvote');
      final response = await http.post(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error upvoting post: $e');
      return null;
    }
  }

  /// Toggle downvote on a post. Returns updated vote counts or null on failure.
  static Future<Map<String, dynamic>?> downvotePost(String postId) async {
    try {
      final url = Uri.parse('$baseUrl/posts/$postId/downvote');
      final response = await http.post(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error downvoting post: $e');
      return null;
    }
  }

  /// Report a post or user
  static Future<bool> report({String? targetPostId, String? targetUserId, required String reason}) async {
    try {
      final url = Uri.parse('$baseUrl/report');
      final body = <String, dynamic>{'reason': reason};
      if (targetPostId != null) body['targetPostId'] = targetPostId;
      if (targetUserId != null) body['targetUserId'] = targetUserId;

      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode(body),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error reporting: $e');
      return false;
    }
  }
}

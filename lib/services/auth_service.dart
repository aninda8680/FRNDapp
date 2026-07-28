import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';
import '../config/dev_config.dart';

enum AuthResult {
  /// Existing user, correct password — go straight to profile setup.
  success,

  /// New user — OTP was sent, show OTP verification screen.
  needsOtp,

  /// Existing user but wrong password — tell the user to try again.
  wrongPassword,

  /// Network error or unexpected server response.
  failure,
}

class AuthService {
  static const String baseUrl = 'https://frnd-api-n3hv.onrender.com/api/auth';

  // Store the session cookie (JWT token from the HTTP-only cookie header)
  static String? _cookie;
  
  /// The logged-in user's MongoDB _id, populated after getProfile() succeeds
  static String? userId;

  /// JWT token or auth cookie getter
  static String? get token => _cookie;

  /// Initialize the auth service by loading the stored cookie.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cookie = prefs.getString('auth_cookie');
  }

  /// Save the cookie to SharedPreferences.
  static Future<void> _saveCookie(String? cookie) async {
    _cookie = cookie;
    final prefs = await SharedPreferences.getInstance();
    if (cookie != null) {
      await prefs.setString('auth_cookie', cookie);
    } else {
      await prefs.remove('auth_cookie');
    }
  }

  /// Logout the user by clearing the session and all local cache.
  static Future<void> logout() async {
    _cookie = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Ensure all cached data/preferences are completely wiped
  }

  /// Main entry point for the "Sign Up / Login" button.
  ///
  /// The backend returns 401 for BOTH "wrong password" and "user not found" on
  /// the login endpoint, so we cannot use login-first to distinguish new users.
  ///
  /// Correct flow:
  ///   1. Try SIGNUP first.
  ///      • 201  → new user created, OTP sent       → [AuthResult.needsOtp]
  ///      • 400/409/other → email already exists    → fall through to login
  ///   2. Try LOGIN with the same credentials.
  ///      • 200  → existing user, correct password  → [AuthResult.success]
  ///      • 401  → existing user, WRONG password    → [AuthResult.wrongPassword]
  ///      • other→ unexpected error                 → [AuthResult.failure]
  static Future<AuthResult> signupOrLogin(String email, String password) async {
    try {
      // ── Step 1: Try signup (new-user path) ─────────────────────────────────
      final signupRes = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('[Auth] Signup → ${signupRes.statusCode}: ${signupRes.body}');

      if (signupRes.statusCode == 201) {
        // Brand new user — OTP has been sent to their college email
        _updateCookie(signupRes);
        return AuthResult.needsOtp;
      }

      // ── Step 2: Signup failed → email exists → try login ───────────────────
      final loginRes = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identity': email, 'password': password}),
      );

      print('[Auth] Login → ${loginRes.statusCode}: ${loginRes.body}');

      if (loginRes.statusCode == 200) {
        _updateCookie(loginRes);
        return AuthResult.success;
      }

      if (loginRes.statusCode == 401 || loginRes.statusCode == 403) {
        return AuthResult.wrongPassword;
      }

      print('[Auth] Both signup and login failed.');
      return AuthResult.failure;
    } catch (e) {
      print('[Auth] Error: $e');
      return AuthResult.failure;
    }
  }

  /// Verifies the OTP entered by the user after signup.
  static Future<bool> verifyOtp(String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: _getHeaders(),
        body: jsonEncode({'otp': otp}),
      );

      print('[Auth] Verify OTP → ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('[Auth] Error verifying OTP: $e');
      return false;
    }
  }

  /// Requests a fresh OTP be sent to the user's email.
  /// Rate-limited: 2-minute cooldown, max 3 resends per session.
  /// Returns true on success (200), false otherwise.
  static Future<bool> resendOtp() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-otp'),
        headers: _getHeaders(),
      );

      print('[Auth] Resend OTP → ${response.statusCode}: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('[Auth] Error resending OTP: $e');
      return false;
    }
  }

  /// Sends a password reset link to the given email.
  /// Always returns the same response regardless of whether the email exists
  /// (to prevent email enumeration). Returns true if the request itself
  /// succeeded (200), false on network error.
  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('[Auth] Forgot password → ${response.statusCode}: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('[Auth] Error sending reset link: $e');
      return false;
    }
  }

  static void _updateCookie(http.Response response) {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      final index = rawCookie.indexOf(';');
      final newCookie = (index == -1) ? rawCookie : rawCookie.substring(0, index);
      _saveCookie(newCookie);
      print('[Auth] Cookie saved: $newCookie');
    }
  }

  /// Updates the user's profile.
  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (DevConfig.bypassAuth) {
      print('Bypassing API Update. Payload: ${jsonEncode(data)}');
      return true;
    }

    try {
      final response = await http.put(
        Uri.parse('https://frnd-api-n3hv.onrender.com/api/users/me'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return true;
      }
      print('Profile update failed: ${response.body}');
      return false;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  static Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_cookie != null) {
      headers['cookie'] = _cookie!;
    }
    return headers;
  }

  /// Fetches the authenticated user's own full profile.
  static Future<Map<String, dynamic>?> getProfile() async {
    if (DevConfig.bypassAuth) {
      return {
        "profileCompletionPercentage": 75,
        "name": "Alex",
        "age": 20,
        "school": "Adamas University",
        "course": "CSE",
        "bio": "Leveling up in the game of life. Looking for a player 2.",
        "hobbies": ["Gaming", "Coding"],
        "interests": [
          { "segmentId": "gaming_tech", "interestId": "coding", "label": "Coding", "emoji": "💻" },
          { "segmentId": "sports_fitness", "interestId": "football", "label": "Football", "emoji": "⚽" }
        ],
        "prompts": [
          {
            "promptId": "q01",
            "sectionId": "questions",
            "question": "What's a random skill you're weirdly proud of?",
            "answer": "Solving a Rubik's cube in 30 seconds"
          }
        ],
        "lookingFor": "dating",
        "pictures": [{"url": "https://dummyimage.com/600x800"}],
      };
    }

    try {
      final response = await http.get(
        Uri.parse('https://frnd-api-n3hv.onrender.com/api/users/me'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'] as Map<String, dynamic>?;
        if (user != null) {
          userId = user['_id'] as String?;
        }
        return user;
      }
      print('Failed to fetch profile: ${response.body}');
      return null;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  /// Checks if the profile has been fully set up (>= 75%).
  static bool isProfileComplete(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    
    // Use the profileCompletionPercentage returned from the backend.
    // Fallback to profileCompletion just in case, default to 0 if missing.
    final completion = profile['profileCompletionPercentage'] ?? profile['profileCompletion'];
    final num percentage = (completion is num) ? completion : 0;
    
    return percentage >= 75;
  }

  /// Uploads a picture to the backend and returns the picture object { url, fileId }
  static Future<Map<String, dynamic>?> uploadPicture(List<int> imageBytes, String filename) async {
    if (DevConfig.bypassAuth) {
      return {
        "url": "https://dummyimage.com/600x800",
        "fileId": "dummy_${DateTime.now().millisecondsSinceEpoch}"
      };
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://frnd-api-n3hv.onrender.com/api/upload/picture'),
      );

      if (_cookie != null) {
        request.headers['cookie'] = _cookie!;
      }

      final Uint8List uint8ListBytes = imageBytes is Uint8List ? imageBytes : Uint8List.fromList(imageBytes);
      final compressedBytes = await FlutterImageCompress.compressWithList(
        uint8ListBytes,
        minWidth: 1080,
        quality: 80,
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'picture',
          compressedBytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // No autoSave because we pass the pictures array in updateProfile

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['picture'] as Map<String, dynamic>?;
      }
      print('Failed to upload picture: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('Error uploading picture: $e');
      return null;
    }
  }
}

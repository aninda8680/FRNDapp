import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'chat_db.dart';
import '../config/dev_config.dart';

enum AuthResult {
  /// Existing user, correct password — go straight to profile setup.
  success,

  /// New user — OTP was sent, show OTP verification screen.
  needsOtp,

  /// Existing user but wrong password — tell the user to try again.
  wrongPassword,

  /// Email does not exist in the database.
  userNotFound,

  /// Network error or unexpected server response.
  failure,
}

class AuthService {
  static const String baseUrl = 'https://frnd-api-n3hv.onrender.com/api/auth';
  
  static const _secureStorage = FlutterSecureStorage();

  // Store the session cookie (JWT token from the HTTP-only cookie header)
  static String? _cookie;
  
  /// The logged-in user's MongoDB _id, populated after getProfile() succeeds
  static String? userId;
  
  /// Cached basic profile info
  static String? userName;
  static String? userGender;

  /// Cached full user profile schema
  static Map<String, dynamic>? userProfile;

  /// JWT token or auth cookie getter
  static String? get token => _cookie;

  /// Initialize the auth service by loading the stored cookie.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Securely read the token
    _cookie = await _secureStorage.read(key: 'auth_cookie');
    
    if (_cookie == null || _cookie!.isEmpty) {
      _cookie = null;
      userProfile = null;
      userName = null;
      userGender = null;
      return;
    }
    
    // Read cached user schema
    final userStr = prefs.getString('user_session_v1');
    if (userStr != null) {
      try {
        userProfile = jsonDecode(userStr) as Map<String, dynamic>;
        userName = userProfile?['name'] as String?;
        userGender = userProfile?['gender'] as String?;
      } catch (e) {
        print('[Auth] Error decoding cached profile: $e');
      }
    }
  }

  /// Save the cookie to secure storage.
  static Future<void> _saveCookie(String? cookie) async {
    _cookie = cookie;
    if (cookie != null) {
      await _secureStorage.write(key: 'auth_cookie', value: cookie);
    } else {
      await _secureStorage.delete(key: 'auth_cookie');
    }
  }

  /// Logout the user by clearing the session and all local cache.
  static Future<void> logout() async {
    _cookie = null;
    userId = null;
    userName = null;
    userGender = null;
    userProfile = null;
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await ChatDB.clearAll(); // Wipe all locally cached messages on logout
  }

  /// Dedicated Login endpoint for existing users.
  static Future<AuthResult> loginOnly(String email, String password) async {
    try {
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

      final bodyStr = loginRes.body.toLowerCase();
      if (loginRes.statusCode == 404 ||
          bodyStr.contains('user not found') ||
          bodyStr.contains('not found') ||
          bodyStr.contains('does not exist') ||
          bodyStr.contains('no user')) {
        return AuthResult.userNotFound;
      }

      if (loginRes.statusCode == 401 || loginRes.statusCode == 403) {
        return AuthResult.wrongPassword;
      }

      return AuthResult.failure;
    } catch (e) {
      print('[Auth] Error during login: $e');
      return AuthResult.failure;
    }
  }

  /// Dedicated Signup endpoint for new users.
  static Future<AuthResult> signupOnly(String email, String password) async {
    try {
      final signupRes = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('[Auth] Signup → ${signupRes.statusCode}: ${signupRes.body}');

      if (signupRes.statusCode == 201) {
        _updateCookie(signupRes);
        return AuthResult.needsOtp;
      }

      if (signupRes.statusCode == 400 || signupRes.statusCode == 409) {
        // User already exists, try logging in
        return signupOrLogin(email, password);
      }

      return AuthResult.failure;
    } catch (e) {
      print('[Auth] Error during signup: $e');
      return AuthResult.failure;
    }
  }

  /// Combined signup or login fallback.
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
    try {
      final response = await http.put(
        Uri.parse('https://frnd-api-n3hv.onrender.com/api/users/me'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        
        // Update the full cached profile with the new fields
        if (userProfile != null) {
          userProfile!.addAll(data);
          userName = userProfile?['name'] as String?;
          userGender = userProfile?['gender'] as String?;
          
          await prefs.setString('user_session_v1', jsonEncode(userProfile));
          await prefs.setString('last_synced_at', DateTime.now().toIso8601String());
        }

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
    if (_cookie == null || _cookie!.isEmpty) return null;
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
          userProfile = user;
          userName = user['name'] as String?;
          userGender = user['gender'] as String?;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_session_v1', jsonEncode(user));
          await prefs.setString('last_synced_at', DateTime.now().toIso8601String());
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

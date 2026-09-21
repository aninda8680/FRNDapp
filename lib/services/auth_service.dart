import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'chat_db.dart';
import '../config/dev_config.dart';
import 'fcm_token_manager.dart';
import 'package:flutter/painting.dart';
import 'image_cache_manager.dart';

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

  /// Human-readable message from the last failed auth call, when the server
  /// provided one (e.g. account banned/suspended). Screens show this instead
  /// of a generic message so failures are never mislabelled.
  static String? lastError;

  /// Pulls the `error`/`message` string out of a JSON response body.
  static String? _serverMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'] ?? decoded['message'];
        if (err is String && err.trim().isNotEmpty) return err.trim();
      }
    } catch (_) {}
    return null;
  }

  /// True when the server body indicates the email is already registered.
  /// Used to decide whether falling back from signup to login is valid —
  /// validation errors (short password, underage, bad input) must NOT
  /// trigger a spurious login attempt.
  static bool _isEmailTaken(String body) {
    final lower = body.toLowerCase();
    return lower.contains('already registered') ||
        lower.contains('already taken') ||
        lower.contains('already exists');
  }

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
        userId = userProfile?['_id'] as String?;
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
    try {
      if (_cookie != null) {
        await http.post(Uri.parse('$baseUrl/logout'), headers: _getHeaders());
      }
    } catch (_) {} // best-effort server logout

    if (userId != null) {
      await FcmTokenManager.invalidateToken(userId!);
    }
    _cookie = null;
    userId = null;
    userName = null;
    userGender = null;
    userProfile = null;
    lastError = null;
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await ChatDB.clearAll(); // Wipe all locally cached messages on logout
    
    // Wipe all locally cached images on logout (disk + memory)
    try {
      await AppImageCacheManager.sharedCacheManager.emptyCache();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      print('[Auth] Error clearing image cache during logout: $e');
    }
  }

  /// Deletes the user account permanently and clears local session.
  static Future<bool> deleteAccount() async {
    try {
      if (_cookie != null) {
        final res = await http.delete(Uri.parse('$baseUrl/account'), headers: _getHeaders());
        if (res.statusCode == 200) {
          // Successfully deleted from server, clean up locally
          await logout();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }

  /// Dedicated Login endpoint for existing users.
  static Future<AuthResult> loginOnly(String email, String password) async {
    lastError = null;
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

      lastError = _serverMessage(loginRes.body);
      final bodyStr = loginRes.body.toLowerCase();
      if (loginRes.statusCode == 404 ||
          bodyStr.contains('user not found') ||
          bodyStr.contains('does not exist') ||
          bodyStr.contains('no user')) {
        return AuthResult.userNotFound;
      }

      if (loginRes.statusCode == 401 || loginRes.statusCode == 403) {
        // A ban/suspension notice is not a wrong password — surface it as a
        // failure so the UI shows the server's message instead of a lie.
        if (loginRes.statusCode == 403 ||
            bodyStr.contains('ban') ||
            bodyStr.contains('suspend')) {
          return AuthResult.failure;
        }
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
    lastError = null;
    try {
      final signupRes = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('[Auth] Signup → ${signupRes.statusCode}: ${signupRes.body}');

      if (signupRes.statusCode == 201) {
        _updateCookie(signupRes);
        // Non-college emails skip OTP per the API contract (otpSent: false,
        // email already verified) — those users go straight through.
        try {
          final decoded = jsonDecode(signupRes.body);
          if (decoded is Map<String, dynamic>) {
            if (decoded['otpSent'] == false) return AuthResult.success;
            final user = decoded['user'];
            if (user is Map<String, dynamic> &&
                user['emailVerified'] == true) {
              return AuthResult.success;
            }
          }
        } catch (_) {}
        return AuthResult.needsOtp;
      }

      if ((signupRes.statusCode == 400 || signupRes.statusCode == 409) &&
          _isEmailTaken(signupRes.body)) {
        // User already exists — fall through to login.
        return loginOnly(email, password);
      }

      // Validation failure (short password, underage, bad input, …):
      // report it instead of firing a misleading login attempt.
      lastError = _serverMessage(signupRes.body);
      return AuthResult.failure;
    } catch (e) {
      print('[Auth] Error during signup: $e');
      return AuthResult.failure;
    }
  }

  /// Combined signup or login fallback.
  static Future<AuthResult> signupOrLogin(String email, String password) async {
    lastError = null;
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
      // Only fall through when the server says the email is taken. A 400 for
      // any other reason (validation) must not trigger a login attempt.
      if (!_isEmailTaken(signupRes.body)) {
        lastError = _serverMessage(signupRes.body);
        return AuthResult.failure;
      }

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

      lastError = _serverMessage(loginRes.body);
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
        lastError = null;
        return true;
      }
      lastError = _serverMessage(response.body);
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
      if (response.statusCode == 200) {
        lastError = null;
        return true;
      }
      lastError = _serverMessage(response.body);
      return false;
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
        // Fetch the fresh full profile from the server so that server-computed
        // fields like `profileCompletionPercentage` are included in the cache.
        // This is critical: without it, the cached profile lacks the completion
        // percentage and main.dart incorrectly routes back to /setup on next launch.
        await getProfile();

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

          if (userId != null) {
            // Register FCM token now that we have a valid user ID (e.g. after login)
            FcmTokenManager.registerDeviceToken(userId!).catchError((e) {
              print('Failed to register FCM token during getProfile: $e');
            });
          }
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

  static bool isEmailVerified(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    return profile['emailVerified'] == true;
  }

  static bool isProfileComplete(Map<String, dynamic>? profile) {
    if (profile == null) return false;

    // Primary check: hasEnteredWorld is set to true by _createProfile()
    // after the user completes onboarding and taps "ENTER WORLD".
    // This is the authoritative signal that profile setup is done.
    if (profile['hasEnteredWorld'] == true) return true;

    // Fallback: for accounts created before hasEnteredWorld was tracked,
    // treat gender being set as a sufficient signal (same as previous logic).
    final gender = profile['gender'];
    return gender != null && gender.toString().trim().isNotEmpty;
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

  /// Shared post-auth routing: unverified users must verify first, users
  /// with an incomplete profile finish setup, everyone else goes to main.
  /// Returns the route string the caller should navigate to.
  static Future<String> nextRouteAfterAuth() async {
    final profile = await AuthService.getProfile();
    if (profile == null) return '/onboarding';
    if (!AuthService.isEmailVerified(profile)) return '/otp';
    return AuthService.isProfileComplete(profile) ? '/main' : '/setup';
  }
}

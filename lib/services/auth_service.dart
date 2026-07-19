import 'dart:convert';
import 'package:http/http.dart' as http;
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
      _cookie = (index == -1) ? rawCookie : rawCookie.substring(0, index);
      print('[Auth] Cookie saved: $_cookie');
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
}

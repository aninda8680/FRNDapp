class DevConfig {
  /// Toggle this to false when connecting to the real backend
  /// When true, auth (login/signup/OTP) will be skipped and automatically redirect to the next screen.
  static const bool bypassAuth = false;

  /// Set this to a route string (e.g. '/edit_profile') to skip directly to that screen on app start.
  /// Set to null to use standard routing.
  static const String? initialRouteOverride = null;
}

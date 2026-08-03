import 'package:version/version.dart';

/// Represents the remote application configuration fetched from Firestore.
class AppVersion {
  /// The latest available version of the app.
  final String latestVersion;

  /// The minimum required version of the app to continue using it.
  final String minimumVersion;

  /// Whether the app is currently in maintenance mode.
  final bool maintenance;

  /// The URL to the app's store page.
  final String playStoreUrl;

  const AppVersion({
    required this.latestVersion,
    required this.minimumVersion,
    required this.maintenance,
    required this.playStoreUrl,
  });

  /// Creates an [AppVersion] from a Firestore document data map.
  /// Uses safe fallbacks to ensure parsing never fails if fields are missing or mistyped.
  factory AppVersion.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const AppVersion(
        latestVersion: '0.0.0',
        minimumVersion: '0.0.0',
        maintenance: false,
        playStoreUrl: '',
      );
    }

    return AppVersion(
      latestVersion: data['latestVersion'] as String? ?? '0.0.0',
      minimumVersion: data['minimumVersion'] as String? ?? '0.0.0',
      maintenance: data['maintenance'] as bool? ?? false,
      playStoreUrl: data['playStoreUrl'] as String? ?? '',
    );
  }

  /// Compares two semantic version strings (e.g., "1.2.0" and "1.1.0").
  /// Returns:
  ///   -1 if [v1] is less than [v2]
  ///    0 if [v1] is equal to [v2]
  ///    1 if [v1] is greater than [v2]
  static int compareVersions(String v1, String v2) {
    try {
      final version1 = Version.parse(v1);
      final version2 = Version.parse(v2);
      return version1.compareTo(version2);
    } catch (e) {
      // If version parsing fails, default to 0 (equal) to fail open
      return 0;
    }
  }
}

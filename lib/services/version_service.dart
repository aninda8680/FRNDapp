import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_version.dart';

/// The possible outcomes of a version check operation.
enum UpdateStatus {
  maintenance,
  forceUpdate,
  optionalUpdate,
  upToDate,
  checkFailed,
}

/// A wrapper class to hold the result of the version check and the fetched remote config.
class VersionCheckResult {
  final UpdateStatus status;
  final AppVersion? appVersion;

  const VersionCheckResult({
    required this.status,
    this.appVersion,
  });
}

/// Service responsible for comparing the installed app version with the remote configuration.
class VersionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks the current app version against the remote configuration in Firestore.
  /// Applies the priority logic: maintenance -> force update -> optional update.
  /// Never throws an exception; returns [UpdateStatus.checkFailed] on error.
  Future<VersionCheckResult> checkVersion() async {
    try {
      // a. Get installed version
      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersion = packageInfo.version;

      // b. Fetch app_config/version from Firestore with a 5-second timeout
      final docSnapshot = await _firestore
          .collection('app_config')
          .doc('version')
          .get()
          .timeout(const Duration(seconds: 5));

      if (!docSnapshot.exists) {
        return const VersionCheckResult(status: UpdateStatus.checkFailed);
      }

      // c. Parse into AppVersion model
      final appVersion = AppVersion.fromMap(docSnapshot.data());

      // d. Apply priority logic
      
      // Priority 1: Maintenance
      if (appVersion.maintenance) {
        return VersionCheckResult(status: UpdateStatus.maintenance, appVersion: appVersion);
      }

      // Priority 2: Minimum Version (Force Update)
      if (AppVersion.compareVersions(installedVersion, appVersion.minimumVersion) < 0) {
        return VersionCheckResult(status: UpdateStatus.forceUpdate, appVersion: appVersion);
      }

      // Priority 3: Latest Version (Optional Update)
      if (AppVersion.compareVersions(installedVersion, appVersion.latestVersion) < 0) {
        return VersionCheckResult(status: UpdateStatus.optionalUpdate, appVersion: appVersion);
      }

      // Default: Up to date
      return VersionCheckResult(status: UpdateStatus.upToDate, appVersion: appVersion);
    } catch (e) {
      // e. On any exception (network failure, timeout, missing doc, parse error) 
      // return checkFailed and log the error, failing open.
      print('Version check failed: $e');
      return const VersionCheckResult(status: UpdateStatus.checkFailed);
    }
  }
}

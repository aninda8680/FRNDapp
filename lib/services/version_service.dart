import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

/// Service responsible for comparing the installed app version with the remote
/// configuration in Firestore.
class VersionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks the current app version against the remote configuration in Firestore.
  /// Applies the priority logic: maintenance → force update → optional update.
  /// Never throws; returns [UpdateStatus.checkFailed] on any error, failing open.
  Future<VersionCheckResult> checkVersion() async {
    try {
      // a. Get installed version and remote config in parallel for speed.
      final results = await Future.wait([
        PackageInfo.fromPlatform(),
        _firestore
            .collection('app_config')
            .doc('version')
            .get()
            .timeout(const Duration(seconds: 5)),
      ]);

      final packageInfo = results[0] as PackageInfo;
      final docSnapshot = results[1] as DocumentSnapshot<Map<String, dynamic>>;

      if (!docSnapshot.exists) {
        debugPrint('[VersionService] app_config/version document not found.');
        return const VersionCheckResult(status: UpdateStatus.checkFailed);
      }

      final installedVersion = packageInfo.version;

      // b. Parse into AppVersion model (includes sha256 if present)
      final appVersion = AppVersion.fromMap(docSnapshot.data());

      debugPrint(
        '[VersionService] installed=$installedVersion '
        'latest=${appVersion.latestVersion} '
        'minimum=${appVersion.minimumVersion} '
        'maintenance=${appVersion.maintenance}',
      );

      // c. Apply priority logic

      // Priority 1: Maintenance
      if (appVersion.maintenance) {
        return VersionCheckResult(
            status: UpdateStatus.maintenance, appVersion: appVersion);
      }

      // Priority 2: Minimum Version (Force Update)
      if (AppVersion.compareVersions(
              installedVersion, appVersion.minimumVersion) <
          0) {
        return VersionCheckResult(
            status: UpdateStatus.forceUpdate, appVersion: appVersion);
      }

      // Priority 3: Latest Version (Optional Update)
      if (AppVersion.compareVersions(
              installedVersion, appVersion.latestVersion) <
          0) {
        return VersionCheckResult(
            status: UpdateStatus.optionalUpdate, appVersion: appVersion);
      }

      // Default: Up to date
      return VersionCheckResult(
          status: UpdateStatus.upToDate, appVersion: appVersion);
    } catch (e) {
      // On any exception (network failure, timeout, missing doc, parse error)
      // return checkFailed and log, failing open.
      debugPrint('[VersionService] checkVersion failed: $e');
      return const VersionCheckResult(status: UpdateStatus.checkFailed);
    }
  }
}

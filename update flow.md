# App Update Flow Documentation

This document explains the end-to-end update flow of the FRND app. The app features a highly robust custom update system that enforces version constraints, supports maintenance mode, handles background downloading, and can seamlessly fetch updates from GitHub Releases.

---

## 1. The Version Check Flow (`SplashVersionScreen`)

The update flow is triggered as soon as the app opens. `SplashVersionScreen` acts as a gatekeeper.

1. **Initialization:** When the app launches, `SplashVersionScreen` displays a loading indicator while it performs the version check.
2. **Fetching Configuration:** It calls `VersionService.checkVersion()`, which queries the `app_config/version` document in Firestore.
3. **Version Comparison:** The app reads the installed version (using the `package_info_plus` package) and compares it against the remote Firestore config using semantic versioning.
4. **Routing:** Depending on the priority logic, the screen will either route the user to the `targetRoute` (e.g., Home) or show a blocking UI (Maintenance, Force Update, or Optional Update).

### Code Snippet: Routing Logic
```dart
Future<void> _runVersionCheck() async {
  setState(() {
    _isChecking = true;
    _isMaintenance = false;
  });

  final result = await _versionService.checkVersion();

  if (!mounted) return;

  switch (result.status) {
    case UpdateStatus.maintenance:
      setState(() {
        _isChecking = false;
        _isMaintenance = true;
      });
      break;

    case UpdateStatus.forceUpdate:
      setState(() => _isChecking = false);
      _showForceUpdateDialog(
        result.appVersion?.playStoreUrl ?? '',
        result.appVersion?.latestVersion ?? '',
      );
      break;

    case UpdateStatus.optionalUpdate:
      _showOptionalUpdateDialogAndProceed(
        result.appVersion?.latestVersion ?? '',
        result.appVersion?.playStoreUrl ?? '',
      );
      break;

    case UpdateStatus.upToDate:
    case UpdateStatus.checkFailed:
      _navigateToHome();
      break;
  }
}
```

---

## 2. Priority Logic & Firestore Configuration

The `VersionService` evaluates the fetched data and assigns an `UpdateStatus` based on a strict priority order. The data is parsed into the `AppVersion` model.

### Firestore Document Structure (`app_config/version`)
The Firestore document must contain the following fields:
- `maintenance` (bool): If `true`, the app is down for maintenance.
- `minimumVersion` (String): The lowest allowed version to use the app.
- `latestVersion` (String): The newest available version.
- `playStoreUrl` (String): The URL to download the new APK (often a GitHub Release URL).

### Code Snippet: Priority Evaluation
The logic is built to prioritize critical statuses first, failing open if something goes wrong:

```dart
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
```

---

## 3. The Download and Installation Process

Once the user chooses (or is forced) to update, the background download starts.

### `UpdateDownloadService` (State Management)
This is a singleton service that owns the update's lifecycle. It keeps the download running in the background and exposes state via `ValueNotifier`s so any UI element can react to the download status.

```dart
class UpdateDownloadService {
  final ValueNotifier<double> progress = ValueNotifier(0.0);
  final ValueNotifier<DownloadState> state = ValueNotifier(DownloadState.idle);
  // ...
}
```

### `AppUpdater` (The Core Engine)
`AppUpdater` handles the actual networking and Android-specific file system operations.

**1. Remote Size Resolution:** Before downloading, it fires a `HEAD` request to find the total APK size (resolving GitHub redirects).
```dart
Future<int> _fetchRemoteSize(String url) async {
  try {
    final response = await _dio.head<dynamic>(
      url,
      options: Options(
        headers: {'Accept': 'application/octet-stream'},
        followRedirects: true,
        maxRedirects: 5, // Important for GitHub Releases
      ),
    );
    final raw = response.headers.value('content-length');
    return raw != null ? (int.tryParse(raw) ?? 0) : 0;
  } catch (_) {
    return 0;
  }
}
```

**2. Smart Caching & Resuming:** If a download was interrupted (e.g., app closed, network dropped), it uses HTTP `Range` headers to resume the download from where it stopped.
```dart
final isResume = localSize > 0 && remoteSize > 0 && localSize < remoteSize;

await _dio.download(
  url,
  filePath,
  cancelToken: _cancelToken,
  deleteOnError: false, // Keep partial file so we can resume next time
  onReceiveProgress: (received, total) {
    // ... calculate and broadcast progress
  },
  options: Options(
    responseType: ResponseType.stream,
    headers: {
      'Accept': 'application/octet-stream',
      // Resume from where we left off if partial download exists
      if (isResume) 'Range': 'bytes=$localSize-',
    },
  ),
);
```

**3. Cleanup and Installation:** Once complete, it deletes old cached APKs to save storage space and triggers the Android Package Installer natively.
```dart
final result = await OpenFilex.open(filePath);
if (result.type != ResultType.done) {
  throw Exception('Installer could not be opened: ${result.message}');
}
```

---

## 4. GitHub Release Integration

While the configuration key is named `playStoreUrl`, this system is perfectly designed to handle direct APK downloads from **GitHub Releases**.

### Handling Redirects
When you link to a GitHub Release asset (e.g., `https://github.com/user/repo/releases/download/v1.2.0/app-release.apk`), GitHub does not serve the file directly. Instead, it **redirects (302)** the request to an AWS S3/CDN bucket where the actual binary is stored.

The `AppUpdater` specifically configures its Dio HTTP client to handle this:
```dart
final Dio _dio = Dio(BaseOptions(
  // Critical: GitHub release URLs redirect to CDN — must follow
  followRedirects: true,
  maxRedirects: 5,
  receiveTimeout: const Duration(minutes: 15),
  connectTimeout: const Duration(seconds: 30),
));
```

### How to Release a New Version
1. Build the release APK (`flutter build apk`).
2. Create a new Release on GitHub and attach the APK.
3. Copy the direct download link for the APK asset.
4. Go to Firebase Firestore > `app_config` > `version`.
5. Update the values:
   - Set `playStoreUrl` to the copied GitHub asset link.
   - Increment `latestVersion` (and `minimumVersion` if it's a mandatory update).
6. The app will immediately pick up the new configuration on the next launch.

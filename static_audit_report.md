# Flutter Codebase Static Audit Report

This report provides an exhaustive, systematic analysis of the provided Flutter/Dart codebase. Every file in `lib/` has been manually inspected.

## === SECTION 1: DEPENDENCIES (pubspec.yaml) ===

| Package | Version | Purpose | Category | Imported In | Classes/Methods Used |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **flutter** | sdk: flutter | Flutter framework | Core | Most files | `StatelessWidget`, `StatefulWidget`, etc. |
| **cupertino_icons** | `^1.0.8` | iOS style icons | UI | None (implicitly used if cupertino widgets exist) | None explicitly |
| **google_fonts** | `^8.2.0` | Custom typography | UI | `lib/theme/app_theme.dart`<br>`lib/widgets/sketchy_button.dart`<br>`lib/widgets/sketchy_progress_bar.dart`<br>`lib/screens/auth/onboarding_screen.dart` | `GoogleFonts.spaceGrotesk()`<br>`GoogleFonts.inter()`<br>`GoogleFonts.spaceMono()`<br>`GoogleFonts.caveat()` |
| **google_mlkit_selfie_segmentation** | `^0.11.0` | Background removal ML | AI | `lib/services/sticker_cutout_service.dart` | `SelfieSegmenter`, `SegmenterMode`, `InputImage.fromFilePath()` |
| **image** | `^4.9.1` | Image manipulation | Other | `lib/services/sticker_cutout_service.dart` | `img.Image`, `img.decodeImage()`, `img.copyCrop()`, `img.encodePng()`, `img.gaussianBlur()`, `img.compositeImage()` |
| **image_picker** | `^1.2.3` | Gallery/Camera selection | UI/Hardware | `lib/widgets/profile_photo_picker.dart` | `ImagePicker()`, `XFile`, `pickMultiImage()` |
| **path_provider** | `^2.1.6` | Access device file system | Storage | `lib/services/sticker_cutout_service.dart` | `getApplicationDocumentsDirectory()` |
| **image_cropper** | `^12.2.1` | Image cropping UI | UI | `lib/widgets/profile_photo_picker.dart` | `ImageCropper().cropImage()`, `CroppedFile`, `AndroidUiSettings`, `IOSUiSettings` |
| **http** | `^1.6.0` | Network requests | Networking | `lib/services/auth_service.dart` | `http.post()`, `http.get()`, `http.put()`, `http.MultipartRequest()`, `http.MultipartFile.fromBytes()` |
| **http_parser** | `^4.0.2` | HTTP media types | Networking | `lib/services/auth_service.dart` | `MediaType()` |
| **shared_preferences** | `^2.2.3` | Local KV storage | Storage | `lib/services/auth_service.dart` | `SharedPreferences.getInstance()`, `getString()`, `setString()`, `remove()` |

> **⚠️ Dead Dependency Flag:** `google_mlkit_selfie_segmentation`, `image`, and `path_provider` are used exclusively in `lib/services/sticker_cutout_service.dart`. However, the `StickerCutoutService` class is never actually called anywhere in the app, making these packages effectively dead dependencies taking up bundle size.


## === SECTION 2: WIDGET INVENTORY ===

| Widget / File | Type / Reason | Purpose | Parent Callers | Const/Rebuild Flags & Disposals |
| :--- | :--- | :--- | :--- | :--- |
| `FrndApp`<br>(main.dart) | Stateless | Root app, defines theme & routes | `main()` | Const constructors used well. |
| `ProfileCard`<br>(widgets/profile_card.dart) | Stateless | Displays user info over a background photo | `my_profile_screen.dart` | Good const usage. |
| `ProfilePhotoPicker`<br>(widgets/profile_photo_picker.dart) | Stateful (Manages image paths, `_isProcessing` state) | Allows users to pick and crop photos | `edit_profile_screen.dart`, `profile_setup_screen.dart` | Rebuilds locally on image pick. |
| `SketchyButton`<br>(widgets/sketchy_button.dart) | Stateless | Reusable themed button with sparkles | Used across almost all screens | Good const usage. |
| `SketchyContainer`<br>(widgets/sketchy_container.dart) | Stateless | Reusable bordered container | Used across almost all screens | Good const usage. |
| `SketchyIconButton`<br>(widgets/sketchy_icon_button.dart) | Stateless | Reusable bordered icon button | `main_scaffold.dart` | Good const usage. |
| `SketchyProgressBar`<br>(widgets/sketchy_progress_bar.dart) | Stateful (Holds `AnimationController`) | Animated wave progress bar | `profile_setup_screen.dart` | `AnimationController` properly disposed in `dispose()`. Uses `AnimatedBuilder` (efficient rebuilds). |
| `SparkleAccent`<br>(widgets/sparkle_accent.dart) | Stateless | Renders star asset | `sketchy_button.dart`, `splash_screen.dart` | Good const usage. |
| `StickerReveal`<br>(widgets/sticker_reveal.dart) | Stateful (Holds `AnimationController`) | Entrance animation for picked stickers | `profile_photo_picker.dart` | `AnimationController` properly disposed. |
| `MainScaffold`<br>(screens/main_scaffold.dart) | Stateful (Holds `_currentIndex`) | Bottom nav controller | `routes.dart` | `setState` rebuilds entire scaffold. |
| `LoginScreen`<br>(screens/auth/login_screen.dart) | Stateful (Holds `TextEditingController`s & loading state) | Login form | `routes.dart` | `TextEditingController`s disposed correctly. `setState` rebuilds entire view. |
| `OnboardingScreen`<br>(screens/auth/onboarding_screen.dart) | Stateless | Intro graphics | `routes.dart` | Good const usage. |
| `OtpVerificationScreen`<br>(screens/auth/otp_verification_screen.dart) | Stateful (Holds `TextEditingController` & `Timer`) | OTP entry & resend logic | `routes.dart` | `Timer` and `TextEditingController` disposed correctly. |
| `SplashScreen`<br>(screens/auth/splash_screen.dart) | Stateful (Awaits IO logic) | Init & routing logic | `routes.dart` | Single initial load. |
| `CampusEventsScreen`<br>(screens/campus/campus_events_screen.dart) | Stateless | List of events | `main_scaffold.dart` | Could use more consts internally (e.g. list items). |
| `ChatListScreen`<br>(screens/chats/chat_list_screen.dart) | Stateless | List of chats | `main_scaffold.dart` | Hardcoded data loop. |
| `IndividualChatScreen`<br>(screens/chats/individual_chat_screen.dart) | Stateless | Message thread | `routes.dart` | Hardcoded dummy data. |
| `DiscoverFeedScreen`<br>(screens/home/discover_feed_screen.dart) | Stateless | Main discovery feed | `main_scaffold.dart` | Hardcoded dummy data. |
| `UserProfileScreen`<br>(screens/home/user_profile_screen.dart) | Stateless | External profile view | `routes.dart` (Wait, unused? Found no direct calls to it in other widgets, only defined but not routed!) | Not in `routes.dart`! Dead widget. |
| `LikesMatchesScreen`<br>(screens/matches/likes_matches_screen.dart) | Stateless | Match grid | `main_scaffold.dart` | Hardcoded dummy data. |
| `EditProfileScreen`<br>(screens/profile/edit_profile_screen.dart) | Stateful (Holds 7 `TextEditingController`s) | Form to edit user data | `routes.dart` | Controllers disposed correctly. |
| `MyProfileScreen`<br>(screens/profile/my_profile_screen.dart) | Stateful (Fetches data) | Displays logged-in user profile | `main_scaffold.dart` | `setState` rebuilds entire screen on load. |
| `ProfileSetupScreen`<br>(screens/setup/profile_setup_screen.dart) | Stateful (Holds `PageController` & `TextEditingController`s) | Multi-step signup form | `routes.dart` | All controllers properly disposed. |
| Utility Screens (Help, Notifications, Report, Filters, Settings) | Stateless | Standard static UI screens | `routes.dart` | Good const usage. |


## === SECTION 3: FUNCTIONS & UTILITIES ===

| Function Signature / File | Purpose | Call Sites | Type |
| :--- | :--- | :--- | :--- |
| `AuthService.init()`<br>(`services/auth_service.dart`) | Loads session cookie from SharedPreferences | `splash_screen.dart` | Async/IO |
| `AuthService.logout()`<br>(`services/auth_service.dart`) | Clears session cookie | **Unused!** | Async/IO |
| `AuthService.signupOrLogin(email, password)`<br>(`services/auth_service.dart`) | Main auth entry point, handles new/existing logic | `login_screen.dart` | Async/Network |
| `AuthService.verifyOtp(otp)`<br>(`services/auth_service.dart`) | Validates 6-digit OTP | `otp_verification_screen.dart` | Async/Network |
| `AuthService.resendOtp()`<br>(`services/auth_service.dart`) | Requests new OTP | `otp_verification_screen.dart` | Async/Network |
| `AuthService.forgotPassword(email)`<br>(`services/auth_service.dart`) | Sends password reset link | `login_screen.dart` | Async/Network |
| `AuthService.updateProfile(data)`<br>(`services/auth_service.dart`) | Saves profile JSON | `edit_profile_screen.dart`, `profile_setup_screen.dart` | Async/Network |
| `AuthService.getProfile()`<br>(`services/auth_service.dart`) | Fetches user JSON | `splash_screen.dart`, `login_screen.dart`, `my_profile_screen.dart`, `edit_profile_screen.dart` | Async/Network |
| `AuthService.isProfileComplete(profile)`<br>(`services/auth_service.dart`) | Checks if user has name | `splash_screen.dart`, `login_screen.dart` | Pure Logic |
| `AuthService.uploadPicture(bytes, name)`<br>(`services/auth_service.dart`) | Uploads multipart image file | `edit_profile_screen.dart`, `profile_setup_screen.dart` | Async/Network |
| `StickerCutoutService.generateSticker(...)`<br>(`services/sticker_cutout_service.dart`) | Uses ML Kit to remove background and add white border drop shadow | **Unused!** | Async/Compute Heavy |
| `StickerCutoutService._processPixels(...)`<br>(`services/sticker_cutout_service.dart`) | Pixel manipulation logic | **Unused!** | Pure logic |


## === SECTION 4: STATE MANAGEMENT ===

- **Approach:** The app strictly uses **plain `setState`** to manage state. No external state management libraries (Provider, Riverpod, Bloc, GetX) or custom `InheritedWidget`s are implemented.
- **Data Flow:** All API interactions are done via static methods in `AuthService`, and local screens manage their own loading flags (e.g. `_isLoading`, `_isSaving`) and fetch their own data on `initState()`.
- **Rebuild Scope:** Because the app relies entirely on local `setState` at the root of `StatefulWidget`s (such as `MyProfileScreen` or `MainScaffold`), rebuild scopes are overly broad (usually causing the entire `Scaffold` to rebuild on any state change). However, custom widgets like `SketchyProgressBar` and `StickerReveal` efficiently scope their animations using `AnimatedBuilder`.


## === SECTION 5: NAVIGATION & ROUTING ===

- **Routing Method:** Navigator 1.0 (Imperative routing) via `MaterialApp.routes`.
- **Route Table (`lib/routes.dart`):**
  - `/` → `SplashScreen` (auth/splash_screen.dart)
  - `/onboarding` → `OnboardingScreen` (auth/onboarding_screen.dart)
  - `/login` → `LoginScreen` (auth/login_screen.dart)
  - `/otp` → `OtpVerificationScreen` (auth/otp_verification_screen.dart)
  - `/setup` → `ProfileSetupScreen` (setup/profile_setup_screen.dart)
  - `/main` → `MainScaffold` (main_scaffold.dart)
  - `/notifications` → `NotificationsScreen` (utilities/notifications_screen.dart)
  - `/search_filters` → `SearchFiltersScreen` (utilities/search_filters_screen.dart)
  - `/report_block` → `ReportBlockScreen` (utilities/report_block_screen.dart)
  - `/settings` → `SettingsScreen` (utilities/settings_screen.dart)
  - `/help_support` → `HelpSupportScreen` (utilities/help_support_screen.dart)
  - `/chats/individual` → `IndividualChatScreen` (chats/individual_chat_screen.dart)
  - `/edit_profile` → `EditProfileScreen` (profile/edit_profile_screen.dart)
- **Transitions/Hero:** No custom `PageRouteBuilder` or `Hero` widgets are currently implemented.


## === SECTION 6: ASSETS & RESOURCES ===

| Asset | Referenced In |
| :--- | :--- |
| `assets/images/frndlogo.png` | `lib/screens/auth/splash_screen.dart` |
| `assets/images/login.png` | `lib/screens/auth/login_screen.dart` |
| `assets/images/redTreebg.png` | `lib/screens/auth/onboarding_screen.dart` |
| `assets/images/star.jpg` | `lib/widgets/sparkle_accent.dart`, `lib/screens/home/discover_feed_screen.dart` |
| `assets/images/withme.png` | `lib/screens/auth/onboarding_screen.dart` |

> **Unused Assets:** None. All 5 images present in `assets/images/` are actively used in the codebase.


## === SECTION 7: THEMING & DESIGN TOKENS ===

- **Global Theme Location:** Defined in `lib/theme/app_theme.dart` (`AppTheme`).
- **Color Palette (`lib/theme/app_colors.dart`):**
  - `cream`: #FAF4E1
  - `inkBlack`: #0A0A0A
  - `lineBlack`: #141414
  - `white`: #FFFFFF
  - `textColor1`: #650000
  - `textColor2`: #A31534
- **Typography:** Configured globally in `AppTheme.textTheme` utilizing `google_fonts` (`spaceGrotesk`, `inter`, `spaceMono`).
- **Hardcoded Styles (Inconsistencies):**
  - `lib/widgets/profile_card.dart`: Uses hardcoded `Colors.white`, `Colors.black`, `Colors.white70`, `Colors.white30`, and `Colors.transparent`.
  - `lib/screens/profile/my_profile_screen.dart`: Uses hardcoded `Colors.transparent` for the Dialog background.
  - `lib/screens/matches/likes_matches_screen.dart`: Uses `Colors.black` for Divider.
  - `lib/screens/home/user_profile_screen.dart`: Uses `Colors.black` for Divider.


## === SECTION 8: DEAD CODE & RISK FLAGS ===

### 🚨 Routing Crash Risks (CRITICAL)
- **Settings Screen (`lib/screens/utilities/settings_screen.dart`):**
  Tapping "Edit Profile" executes `Navigator.pushNamed(context, '/setup/preview')`. However, the `/setup/preview` route is **not defined** in `routes.dart`, which will cause the app to crash.
- **My Profile Screen (`lib/screens/profile/my_profile_screen.dart`):**
  Tapping "Privacy Policy" executes `Navigator.pushNamed(context, '/privacy_policy')`. The `/privacy_policy` route is **not defined** in `routes.dart`.

### 👻 Dead Code & Unused Elements
- **Dead Import:** `lib/widgets/profile_photo_picker.dart` imports `../services/sticker_cutout_service.dart` but never calls it.
- **Dead Service:** The entirety of `StickerCutoutService` (`lib/services/sticker_cutout_service.dart`) is never called by any active widget or service.
- **Dead Function:** `AuthService.logout()` is defined but never called (settings screen simply navigates back to `/login` without clearing the cookie locally).
- **Dead Widget:** `UserProfileScreen` (`lib/screens/home/user_profile_screen.dart`) is defined but not present in `routes.dart`, nor is it ever pushed using `MaterialPageRoute`.

### ⚠️ Implementation Risks
- **Concurrency & Memory Issue (`ProfilePhotoPicker`):** The image picker allows the user to pick up to 4 images at once. It loops over them and crops them synchronously, returning unoptimized full-size `Uint8List` byte arrays into memory. This has a high risk of triggering OOM (Out of Memory) crashes on lower-end devices.
- **Performance (`StickerCutoutService`):** Though dead code, if invoked, `_processPixels` iterates sequentially over an unscaled image (O(N*M)). Even inside an isolate, instantiating massive `img.Image` objects will cause severe performance degradation.
- **State Handling (`AuthService.signupOrLogin`):** The logic relies on trying signup, and if it fails (assuming email exists), falling back to login. The failure block quietly returns `AuthResult.failure` without exposing the exact server status code (e.g. 500 vs 403), making network issue debugging difficult.

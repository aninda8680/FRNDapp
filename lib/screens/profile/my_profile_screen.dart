import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/profile_card.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_image.dart';
import '../../utils/responsive_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/announcement_service.dart';

const Color _bgCream = Color(0xFFF5EFE0);
const Color _primaryBurgundy = Color(0xFF6B1B35);
const Color _textBlack = Color(0xFF1A1A1A);
const Color _mutedGray = Color(0xFF888888);
const Color _lightDivider = Color(0x121A1A1A);

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String _appVersion = '';
  int _unreadAnnouncementsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchVersion();
    _fetchUnreadAnnouncementsCount();
  }

  Future<void> _fetchUnreadAnnouncementsCount() async {
    final count = await AnnouncementService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadAnnouncementsCount = count;
      });
    }
  }

  Future<void> _fetchVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      debugPrint('Error fetching version: $e');
    }
  }

  Future<void> _fetchProfile() async {
    if (_profileData == null) {
      setState(() {
        _isLoading = true;
      });
    }

    final data = await AuthService.getProfile();

    if (mounted) {
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawGender = _profileData?['gender']?.toString() ?? AuthService.userGender;
    final gender = rawGender?.toLowerCase();
    final isMale = gender == 'male' || gender == 'm';
    final isFemale = gender == 'female' || gender == 'f';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent, // Ensure the background is transparent
      ),
      child: Scaffold(
        backgroundColor: _bgCream,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryBurgundy),
                ),
              )
            : _profileData == null
                ? _buildErrorState()
                : _buildProfileContent(isMale, isFemale),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: _primaryBurgundy),
          SizedBox(height: context.responsiveHeight(16)),
          Text(
            'Failed to load profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _textBlack),
          ),
          SizedBox(height: context.responsiveHeight(24)),
          OutlinedButton(
            onPressed: _fetchProfile,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryBurgundy,
              side: const BorderSide(color: _primaryBurgundy),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('RETRY'),
          ),
          SizedBox(height: context.responsiveHeight(16)),
          TextButton.icon(
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 16, color: _mutedGray),
            label: const Text(
              'Log Out',
              style: TextStyle(color: _mutedGray, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(bool isMale, bool isFemale) {
    final name = _profileData?['name'] ?? _profileData?['username'] ?? 'User';
    final rawUsername = _profileData?['username'];
    final username = rawUsername != null && rawUsername.toString().isNotEmpty 
        ? rawUsername 
        : name.toLowerCase().replaceAll(' ', '');
    final age = _profileData?['age']?.toString() ?? '18';
    final school = _profileData?['school'] ?? 'No School';
    final course = _profileData?['course'] ?? 'No Course';
    final bio = _profileData?['bio'] ?? '';
    final hobbiesList = _profileData?['hobbies'] as List<dynamic>? ?? [];
    final hobbies = hobbiesList.map((e) => e.toString()).toList();
    final lookingFor = _profileData?['lookingFor'];
    final tier = _profileData?['tier']?.toString().toUpperCase() ?? _profileData?['subscriptionTier']?.toString().toUpperCase() ?? 'FREE TIER';
    
    final isGold = tier.contains('GOLD');
    final badgeColors = isGold
        ? const [Color(0xFFFFF2D8), Color(0xFFD4AF37), Color(0xFFFFF2D8)]
        : const [Color(0xFFF5F7FA), Color(0xFFC3CFE2), Color(0xFFF5F7FA)];
    final badgeTextColor = isGold ? const Color(0xFF5C4000) : const Color(0xFF2C3E50);

    String? networkImageUrl;
    final pictures = _profileData?['pictures'] as List<dynamic>?;
    if (pictures != null && pictures.isNotEmpty) {
      networkImageUrl = pictures[0]['url'];
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'MY PROFILE',
                      style: TextStyle(
                        color: _textBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.campaign_rounded, color: _primaryBurgundy, size: 28),
                          if (_unreadAnnouncementsCount > 0)
                            Positioned(
                              right: -2,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$_unreadAnnouncementsCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () async {
                        await context.push('/announcements');
                        if (mounted) {
                          setState(() {
                            _unreadAnnouncementsCount = 0;
                          });
                        }
                        _fetchUnreadAnnouncementsCount();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(color: _lightDivider, height: 1.0),
            SizedBox(height: context.responsiveHeight(16)),
            
            // Stats Card / Hero Element
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(16),
                    child: ProfileCard(
                      name: '@$username',
                      age: age,
                      school: school,
                      course: course,
                      bio: bio,
                      hobbies: hobbies,
                      lookingFor: lookingFor,
                      networkImageUrl: networkImageUrl,
                      fullProfile: _profileData,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryBurgundy, Color(0xFF5A152A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryBurgundy.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    // Avatar with fine ring
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _bgCream.withOpacity(0.5), width: 1.5),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: networkImageUrl != null
                            ? AppImage(
                                url: networkImageUrl,
                                fit: BoxFit.cover,
                                isThumbnail: true,
                              )
                            : const Icon(Icons.person, size: 28, color: _bgCream),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: _bgCream,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: context.responsiveHeight(4)),
                          Text(
                            '@$username • Member since 2026',
                            style: TextStyle(
                              color: _bgCream.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: context.responsiveHeight(24)),
            
            // Settings Section
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                'SETTINGS', 
                style: TextStyle(
                  color: _mutedGray, 
                  fontSize: 11, 
                  fontWeight: FontWeight.w600, 
                  letterSpacing: 2.5, 
                )
              ),
            ),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primaryBurgundy.withOpacity(0.3), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03), 
                    blurRadius: 16, 
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    Icons.star_outline_rounded, 
                    'Passes', 
                    null,
                    badge: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primaryBurgundy.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _primaryBurgundy.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'COMING SOON',
                        style: TextStyle(
                          color: _primaryBurgundy,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat())
                     .shimmer(duration: 1500.ms, color: _primaryBurgundy.withOpacity(0.3))
                     .animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 800.ms),
                  ),
                  const Divider(color: _lightDivider, height: 1, indent: 56),
                  _buildSettingRow(Icons.person_outline_rounded, 'Edit Profile', () async {
                    await context.push('/edit_profile');
                    _fetchProfile();
                  }),

                  const Divider(color: _lightDivider, height: 1, indent: 56),
                  _buildSettingRow(Icons.help_outline_rounded, 'Help & Support', () => context.push('/help_support')),
                  const Divider(color: _lightDivider, height: 1, indent: 56),
                  _buildSettingRow(Icons.privacy_tip_outlined, 'Privacy Policy', () => context.push('/privacy_policy')),
                  const Divider(color: _lightDivider, height: 1, indent: 56),
                  _buildSettingRow(Icons.article_outlined, 'Terms of Service', () => context.push('/terms_of_service')),
                ],
              ),
            ),

            SizedBox(height: context.responsiveHeight(16)),
            
            // Log out button
            Center(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: Icon(Icons.logout_rounded, size: 18, color: _primaryBurgundy.withOpacity(0.8)),
                label: Text(
                  'Log Out', 
                  style: TextStyle(color: _primaryBurgundy.withOpacity(0.8)),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _primaryBurgundy.withOpacity(0.3), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ),
            ),
            
            SizedBox(height: context.responsiveHeight(12)),
            
            // Delete Account button
            Center(
              child: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text('Are you sure you want to permanently delete your account? This action cannot be undone.'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final success = await AuthService.deleteAccount();
                            if (success && context.mounted) {
                              context.go('/login');
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to delete account. Please try again.')),
                              );
                            }
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            
            SizedBox(height: context.responsiveHeight(16)),
            
            // App Version
            if (_appVersion.isNotEmpty)
              Center(
                child: Text(
                  'FRND Buzz $_appVersion',
                  style: TextStyle(
                    color: _mutedGray.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            

            
            SizedBox(height: context.responsiveHeight(100)), // Extra space for floating nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String title, VoidCallback? onTap, {Widget? badge}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20), 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: onTap == null ? _mutedGray : _primaryBurgundy, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onTap == null ? _mutedGray : _textBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (badge != null) ...[
                      const Spacer(),
                      badge,
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, color: _mutedGray, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../../widgets/profile_card.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_image.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

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
    return Scaffold(
      backgroundColor: _bgCream,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryBurgundy),
              ),
            )
          : _profileData == null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: _primaryBurgundy),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _textBlack),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _fetchProfile,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryBurgundy,
              side: const BorderSide(color: _primaryBurgundy),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('RETRY'),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
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

  Widget _buildProfileContent() {
    final name = _profileData?['name'] ?? _profileData?['username'] ?? 'User';
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
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
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
            ),
            Container(color: _lightDivider, height: 1.0),
            const SizedBox(height: 16),
            
            // Stats Card / Hero Element
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(16),
                    child: ProfileCard(
                      name: name,
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
                          const SizedBox(height: 4),
                          Text(
                            '@${name.toLowerCase().replaceAll(' ', '')} • Member since 2026',
                            style: TextStyle(
                              color: _bgCream.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: badgeColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                stops: const [0.0, 0.5, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium_rounded, size: 12, color: badgeTextColor),
                                const SizedBox(width: 4),
                                Text(
                                  '$tier PASS',
                                  style: TextStyle(
                                    color: badgeTextColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
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
                  _buildSettingRow(Icons.star_outline_rounded, 'Premium Passes', () => Navigator.pushNamed(context, '/subscription')),
                  const Divider(color: _lightDivider, height: 1, indent: 56),
                  _buildSettingRow(Icons.person_outline_rounded, 'Edit Profile', () async {
                    await Navigator.pushNamed(context, '/edit_profile');
                    _fetchProfile();
                  }),
                  const Divider(color: _lightDivider, height: 1, indent: 56),
                  _buildSettingRow(Icons.notifications_none_rounded, 'Announcement', () => Navigator.pushNamed(context, '/announcement')),
                  const Divider(color: _lightDivider, height: 1, indent: 56),
                  _buildSettingRow(Icons.help_outline_rounded, 'Help & Support', () => Navigator.pushNamed(context, '/help_support')),
                  const Divider(color: _lightDivider, height: 1, indent: 56),
                  _buildSettingRow(Icons.privacy_tip_outlined, 'Privacy Policy', () => Navigator.pushNamed(context, '/privacy_policy')),
                ],
              ),
            ),

            const SizedBox(height: 16),
            
            // Log out button
            Center(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
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
            
            const SizedBox(height: 100), // Extra space for floating nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20), 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: _primaryBurgundy, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _mutedGray, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}


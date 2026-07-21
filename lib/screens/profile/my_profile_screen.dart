import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/profile_card.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';

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
      appBar: AppBar(
        title: const Text('MY PROFILE'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textColor2),
                ),
              )
            : _profileData == null
                ? _buildErrorState()
                : _buildProfileContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textColor2),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          SketchyButton(
            text: 'RETRY',
            onPressed: _fetchProfile,
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

    String? networkImageUrl;
    final pictures = _profileData?['pictures'] as List<dynamic>?;
    if (pictures != null && pictures.isNotEmpty) {
      networkImageUrl = pictures[0]['url'];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stats Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.textColor2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lineBlack, width: 2),
              boxShadow: const [
                BoxShadow(color: AppColors.lineBlack, offset: Offset(3, 3)),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cream.withOpacity(0.6), width: 2),
                    color: AppColors.cream.withOpacity(0.1),
                  ),
                  child: ClipOval(
                    child: networkImageUrl != null
                        ? Image.network(
                            networkImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, size: 30, color: AppColors.cream),
                          )
                        : const Icon(Icons.person, size: 30, color: AppColors.cream),
                  ),
                ),
                const SizedBox(width: 14),
                // Name — fills remaining space
                Expanded(
                  child: Text(
                    name.toString().toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.cream,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                // Action icons — stacked vertically, right-aligned
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                            ),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.open_in_full, size: 24, color: AppColors.cream),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Settings Content
          Text('SETTINGS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 12),
          Column(
            children: [
              ListTile(
                title: const Text('Edit Profile'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  await Navigator.pushNamed(context, '/edit_profile');
                  _fetchProfile();
                },
              ),
              const Divider(color: AppColors.lineBlack, height: 1),
              ListTile(
                title: const Text('Notifications'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
              const Divider(color: AppColors.lineBlack, height: 1),
              ListTile(
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/help_support'),
              ),
              const Divider(color: AppColors.lineBlack, height: 1),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/privacy_policy'),
              ),
              const Divider(color: AppColors.lineBlack, height: 1),
              ListTile(
                title: const Text('Log Out', style: TextStyle(color: AppColors.textColor2, fontWeight: FontWeight.bold)),
                onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

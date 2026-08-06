import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.push('/edit_profile'),
            ),
            const Divider(color: AppColors.lineBlack),
            ListTile(
              title: const Text('Notifications'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.push('/notifications'),
            ),
            const Divider(color: AppColors.lineBlack),
            ListTile(
              title: const Text('Announcements'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.push('/announcements'),
            ),
            const Divider(color: AppColors.lineBlack),
            ListTile(
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.push('/help_support'),
            ),
            const Divider(color: AppColors.lineBlack),
            ListTile(
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.push('/privacy_policy'),
            ),
            const Divider(color: AppColors.lineBlack),
            ListTile(
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.push('/terms_of_service'),
            ),
            const Divider(color: AppColors.lineBlack),
            ListTile(
              title: const Text('Log Out'),
              onTap: () async {
                await AuthService.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ALERTS')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: 8,
          separatorBuilder: (context, index) => const Divider(color: AppColors.lineBlack, thickness: 1),
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text('New Match Unlocked!', style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text('Check your guild invites.', style: Theme.of(context).textTheme.bodyMedium),
            );
          },
        ),
      ),
    );
  }
}

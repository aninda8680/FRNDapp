import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TAVERN CHATS')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: 10,
          separatorBuilder: (context, index) => const Divider(color: AppColors.lineBlack, thickness: 1),
          itemBuilder: (context, index) {
            return ListTile(
              leading: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.lineBlack, width: 2)),
                child: const Icon(Icons.person),
              ),
              title: Text('Player ${index + 1}', style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text('Are we doing the quest later?', style: Theme.of(context).textTheme.bodyMedium),
              trailing: Text('2m', style: Theme.of(context).textTheme.labelSmall),
              onTap: () => Navigator.pushNamed(context, '/chats/individual'),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../widgets/sketchy_container.dart';
import '../../theme/app_colors.dart';

class IndividualChatScreen extends StatelessWidget {
  const IndividualChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CHAT')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildMessage(context, 'Hey! Wanna party up?', true),
                  _buildMessage(context, 'Sure! When are you free?', false),
                  _buildMessage(context, 'After 5pm', true),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.lineBlack, width: 2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SketchyContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: 999,
                      child: const TextField(
                        decoration: InputDecoration(border: InputBorder.none, hintText: 'Type message...'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(color: AppColors.inkBlack, shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: AppColors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.inkBlack : AppColors.cream,
          border: Border.all(color: AppColors.lineBlack, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isMe ? AppColors.white : AppColors.inkBlack,
          ),
        ),
      ),
    );
  }
}

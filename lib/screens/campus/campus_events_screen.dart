import 'package:flutter/material.dart';
import '../../widgets/sketchy_container.dart';
import '../../theme/app_colors.dart';

class CampusEventsScreen extends StatelessWidget {
  const CampusEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CAMPUS QUESTS')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return SketchyContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lineBlack, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('[ Event Flyer ]')),
                  ),
                  const SizedBox(height: 16),
                  Text('ART CLUB MEETUP', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Today at 5PM • Student Center', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.inkBlack,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('JOIN QUEST', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

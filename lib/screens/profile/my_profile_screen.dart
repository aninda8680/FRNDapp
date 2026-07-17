import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/sketchy_progress_bar.dart';
import '../../theme/app_colors.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY STATS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SketchyContainer(
                child: Row(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.lineBlack, width: 2)),
                      child: const Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ALEX', style: Theme.of(context).textTheme.displayMedium),
                          const SizedBox(height: 4),
                          const SketchyProgressBar(progress: 0.7, leftLabel: 'lv. 20', rightLabel: '7421 exp'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SketchyButton(
                text: 'EDIT PROFILE',
                onPressed: () => Navigator.pushNamed(context, '/setup/preview'), // using preview as placeholder for edit
              ),
            ],
          ),
        ),
      ),
    );
  }
}

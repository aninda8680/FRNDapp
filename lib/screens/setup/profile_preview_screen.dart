import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/sketchy_progress_bar.dart';

class ProfilePreviewScreen extends StatelessWidget {
  const ProfilePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PLAYER CARD')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SketchyProgressBar(
                progress: 1.0,
                leftLabel: 'STEP 5',
                rightLabel: 'READY!',
              ),
              const SizedBox(height: 32),
              SketchyContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.transparent,
                      child: Icon(Icons.person_outline, size: 64),
                    ),
                    const SizedBox(height: 16),
                    Text('ALEX, lv. 20', style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: 8),
                    Text('Computer Science', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.black, thickness: 2),
                    const SizedBox(height: 24),
                    Text('LOOKING FOR: FRIENDS', style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SketchyButton(
                text: 'ENTER WORLD',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

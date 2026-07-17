import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/sketchy_progress_bar.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QUEST TYPE')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SketchyProgressBar(
                progress: 0.8,
                leftLabel: 'STEP 4',
                rightLabel: 'GOALS',
              ),
              const SizedBox(height: 32),
              Text('WHAT ARE YOU LOOKING FOR?', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 16),
              SketchyContainer(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 32),
                    const SizedBox(width: 16),
                    Text('DATING', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SketchyContainer(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline, size: 32),
                    const SizedBox(width: 16),
                    Text('FRIENDS ONLY', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SketchyButton(
                text: 'NEXT STEP',
                onPressed: () => Navigator.pushNamed(context, '/setup/preview'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

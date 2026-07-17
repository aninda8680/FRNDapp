import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/sketchy_progress_bar.dart';

class InterestsScreen extends StatelessWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SKILLS & TRAITS')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SketchyProgressBar(
                progress: 0.6,
                leftLabel: 'STEP 3',
                rightLabel: 'INTERESTS',
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  'Gaming', 'Anime', 'Coding', 'Hiking', 'Music', 'Art', 'Coffee', 'Movies',
                ].map((e) => SketchyContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  borderRadius: 999,
                  child: Text(e, style: Theme.of(context).textTheme.labelLarge),
                )).toList(),
              ),
              const SizedBox(height: 32),
              Text('PERSONALITY PROMPT', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SketchyContainer(
                child: TextField(
                  maxLines: 3,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'A random fact about me...'),
                ),
              ),
              const SizedBox(height: 48),
              SketchyButton(
                text: 'NEXT STEP',
                onPressed: () => Navigator.pushNamed(context, '/setup/preferences'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

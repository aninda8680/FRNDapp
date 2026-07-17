import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/sketchy_progress_bar.dart';

class BasicInfoScreen extends StatelessWidget {
  const BasicInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CREATE CHARACTER')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SketchyProgressBar(
                progress: 0.2,
                leftLabel: 'STEP 1',
                rightLabel: 'BASIC STATS',
              ),
              const SizedBox(height: 32),
              Text('WHAT IS YOUR NAME?', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SketchyContainer(
                child: TextField(decoration: const InputDecoration(border: InputBorder.none, hintText: 'Name')),
              ),
              const SizedBox(height: 24),
              Text('AGE (LEVEL)', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SketchyContainer(
                child: TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(border: InputBorder.none, hintText: '18')),
              ),
              const SizedBox(height: 24),
              Text('MAJOR / CLASS', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SketchyContainer(
                child: TextField(decoration: const InputDecoration(border: InputBorder.none, hintText: 'Computer Science')),
              ),
              const SizedBox(height: 48),
              SketchyButton(
                text: 'NEXT STEP',
                onPressed: () => Navigator.pushNamed(context, '/setup/photos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

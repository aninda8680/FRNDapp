import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Hero illustration placeholder
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text('[ Hero Illustration: Two friends high-fiving ]')),
              ),
              Text(
                    'EVERY STORY STARTS SOMEWHERE',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                                const SizedBox(height: 16),
                                Text(
                                  'Meet new people. Begin as strangers, stay as friends, and maybe find your person.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
              const Spacer(),
              SketchyButton(
                text: 'START ADVENTURE',
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

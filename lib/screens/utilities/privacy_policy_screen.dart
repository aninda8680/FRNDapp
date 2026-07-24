import 'package:flutter/material.dart';
import '../../widgets/sketchy_container.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PRIVACY POLICY')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: SketchyContainer(
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              // TODO: Replace placeholder text with real policy content
              'This is a placeholder for the privacy policy.\n\n'
              'We collect data to make the app work and don\'t sell it to third parties.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

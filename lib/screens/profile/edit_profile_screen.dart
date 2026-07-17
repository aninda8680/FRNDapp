import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EDIT CHARACTER')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('BIO', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SketchyContainer(
                child: TextField(
                  maxLines: 3,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Update your bio...'),
                ),
              ),
              const SizedBox(height: 24),
              SketchyButton(
                text: 'SAVE CHANGES',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

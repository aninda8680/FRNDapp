import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/sketchy_progress_bar.dart';
import '../../theme/app_colors.dart';

class UploadPhotosScreen extends StatelessWidget {
  const UploadPhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AVATAR PHOTOS')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SketchyProgressBar(
                progress: 0.4,
                leftLabel: 'STEP 2',
                rightLabel: 'VISUALS',
              ),
              const SizedBox(height: 32),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return SketchyContainer(
                    child: Center(
                      child: Icon(Icons.add_a_photo_outlined, size: 48, color: AppColors.inkBlack),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              SketchyButton(
                text: 'NEXT STEP',
                onPressed: () => Navigator.pushNamed(context, '/setup/interests'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

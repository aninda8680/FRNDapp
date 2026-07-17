import 'package:flutter/material.dart';
import '../../widgets/sketchy_container.dart';
import '../../theme/app_colors.dart';

class LikesMatchesScreen extends StatelessWidget {
  const LikesMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GUILD INVITES')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('NEW MATCHES', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.lineBlack, width: 2)),
                            child: const Center(child: Icon(Icons.person)),
                          ),
                          const SizedBox(height: 8),
                          Text('Match $index', style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.black, thickness: 2),
              const SizedBox(height: 24),
              Text('PEOPLE WHO LIKED YOU', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return SketchyContainer(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppColors.lineBlack, width: 2)),
                              ),
                              child: const Center(child: Icon(Icons.blur_on, size: 48)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Secret Admirer', style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

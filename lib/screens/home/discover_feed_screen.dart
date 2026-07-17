import 'package:flutter/material.dart';
import '../../widgets/sketchy_container.dart';
import '../../theme/app_colors.dart';

class DiscoverFeedScreen extends StatelessWidget {
  const DiscoverFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DISCOVER'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => Navigator.pushNamed(context, '/search_filters'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SketchyContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.lineBlack, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(child: Text('[ User Photo Placeholder ]')),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('SAM, lv. 19', style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 8),
                      Text('Art Major • Looking for Friends', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Anime', 'Art', 'Coffee'].map((e) => SketchyContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          borderRadius: 999,
                          child: Text(e, style: Theme.of(context).textTheme.labelSmall),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.lineBlack, width: 2)),
                      child: const Icon(Icons.close, size: 32),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: AppColors.inkBlack, shape: BoxShape.circle),
                      child: const Icon(Icons.favorite, color: AppColors.white, size: 40),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.lineBlack, width: 2)),
                      child: const Icon(Icons.star, size: 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/app_image.dart';
import '../../theme/app_colors.dart';
import '../../services/image_cache_manager.dart';

class DiscoverFeedScreen extends StatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen> {
  int _currentIndex = 0;

  // Mock list of profiles
  final List<Map<String, dynamic>> _profiles = [
    {
      'name': 'SAM',
      'age': 19,
      'major': 'Art Major',
      'lookingFor': 'Looking for Friends',
      'tags': ['Anime', 'Art', 'Coffee'],
      'url': 'https://dummyimage.com/600x800/000/fff&text=Sam',
    },
    {
      'name': 'ALEX',
      'age': 20,
      'major': 'CS Major',
      'lookingFor': 'Looking for Dating',
      'tags': ['Coding', 'Gaming', 'Gym'],
      'url': 'https://dummyimage.com/600x800/ff0000/fff&text=Alex',
    },
    {
      'name': 'JORDAN',
      'age': 21,
      'major': 'Business',
      'lookingFor': 'Looking for Networking',
      'tags': ['Finance', 'Travel', 'Food'],
      'url': 'https://dummyimage.com/600x800/00ff00/fff&text=Jordan',
    },
    {
      'name': 'TAYLOR',
      'age': 19,
      'major': 'Biology',
      'lookingFor': 'Looking for Friends',
      'tags': ['Nature', 'Pets', 'Music'],
      'url': 'https://dummyimage.com/600x800/0000ff/fff&text=Taylor',
    }
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchNextImages();
    });
  }

  void _nextProfile() {
    if (_currentIndex < _profiles.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _prefetchNextImages();
    }
  }

  void _prefetchNextImages() {
    // Prefetch next 2 profiles
    for (int i = 1; i <= 2; i++) {
      int nextIndex = _currentIndex + i;
      if (nextIndex < _profiles.length) {
        final url = _profiles[nextIndex]['url'] as String;
        final optimizedUrl = _getOptimizedUrl(url, true);
        precacheImage(
          CachedNetworkImageProvider(
            optimizedUrl,
            cacheManager: AppImageCacheManager.sharedCacheManager,
          ),
          context,
        );
      }
    }
  }

  String _getOptimizedUrl(String url, bool isThumbnail) {
    if (url.isEmpty) return url;
    if (isThumbnail && !url.contains('?tr=')) {
      if (url.contains('?')) {
        return '$url&tr=w-400,h-533';
      } else {
        return '$url?tr=w-400,h-533';
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _profiles.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('DISCOVER')),
        body: const Center(child: Text("No more profiles!")),
      );
    }

    final profile = _profiles[_currentIndex];
    final tags = profile['tags'] as List<String>;

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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AppImage(
                              url: profile['url'],
                              fit: BoxFit.cover,
                              isThumbnail: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('${profile['name']}, lv. ${profile['age']}', style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 8),
                      Text('${profile['major']} • ${profile['lookingFor']}', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((e) => SketchyContainer(
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
                    onTap: _nextProfile,
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.lineBlack, width: 2)),
                      child: const Icon(Icons.close, size: 32),
                    ),
                  ),
                  GestureDetector(
                    onTap: _nextProfile,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: AppColors.inkBlack, shape: BoxShape.circle),
                      child: const Icon(Icons.favorite, color: AppColors.white, size: 40),
                    ),
                  ),
                  GestureDetector(
                    onTap: _nextProfile,
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.lineBlack, width: 2)),
                      child: Image.asset('assets/images/star.jpg', width: 32, height: 32),
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

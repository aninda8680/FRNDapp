import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AppImageCacheManager {
  static const key = 'frndAppImageCache';

  static final CacheManager sharedCacheManager = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 300,
    ),
  );
}

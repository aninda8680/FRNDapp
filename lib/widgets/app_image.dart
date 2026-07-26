import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_cache_manager.dart';
import '../theme/app_colors.dart';

class AppImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isThumbnail;
  final bool showLoadingIndicator;

  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isThumbnail = false,
    this.showLoadingIndicator = true,
  });

  String get _optimizedUrl {
    if (url.isEmpty) return url;
    // Only apply ImageKit transformation params to actual ImageKit URLs.
    // Appending ?tr= to non-ImageKit URLs breaks the request and causes a
    // permanent loading state.
    final isImageKit = url.contains('ik.imagekit.io');
    if (isThumbnail && isImageKit && !url.contains('?tr=')) {
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
    if (url.isEmpty) {
      return _buildError();
    }

    return CachedNetworkImage(
      imageUrl: _optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: AppImageCacheManager.sharedCacheManager,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildError(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.cream,
      child: Center(
        child: showLoadingIndicator
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textColor2),
              )
            : const Icon(
                Icons.image_outlined,
                color: AppColors.lineBlack,
                size: 32,
              ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      color: AppColors.cream,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.lineBlack,
          size: 40,
        ),
      ),
    );
  }
}

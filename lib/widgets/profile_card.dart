import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_image.dart';
import 'full_profile_sheet.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String age;
  final String school;
  final String course;
  final String bio;
  final List<String> hobbies;
  final String? lookingFor;
  final String? localImagePath;
  final Uint8List? localImageBytes;
  final String? networkImageUrl;
  final Map<String, dynamic>? fullProfile;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  const ProfileCard({
    super.key,
    required this.name,
    required this.age,
    required this.school,
    required this.course,
    required this.bio,
    required this.hobbies,
    this.lookingFor,
    this.localImagePath,
    this.localImageBytes,
    this.networkImageUrl,
    this.fullProfile,
    this.onLike,
    this.onPass,
  });

  void _showFullProfile(BuildContext context) {
    if (fullProfile == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: FullProfileSheet(
          profile: fullProfile!,
          onClose: () => Navigator.pop(bottomSheetContext),
          onLike: onLike != null ? () {
            onLike!();
            Navigator.pop(bottomSheetContext); // Close sheet
          } : null,
          onPass: onPass != null ? () {
            onPass!();
            Navigator.pop(bottomSheetContext); // Close sheet
          } : null,
        ),
      ),
    ).then((_) {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
          _showFullProfile(context);
        } else if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      onTap: () => _showFullProfile(context),
      child: Container(
        height: 480,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 32,
              offset: const Offset(0, 16),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Photo
            Container(
              color: AppColors.cream,
              child: _buildBackgroundImage(),
            ),
            
            // 2. Gradient Overlay for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 320,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 3. Info Overlay
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Age
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          '$name, $age',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Department & Year
                  Row(
                    children: [
                      Icon(Icons.school_outlined, size: 18, color: Colors.white.withOpacity(0.85)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$school • $course',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Tags
                  if (hobbies.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hobbies.take(3).map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        ),
                        child: Text(
                          e, 
                          style: const TextStyle(
                            fontSize: 13, 
                            fontWeight: FontWeight.w600, 
                            color: Colors.white,
                            letterSpacing: 0.2,
                          )
                        ),
                      )).toList(),
                    ),
                  ],
                  
                  // Bio
                  const SizedBox(height: 16),
                  Text(
                    bio,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Preference
                  if (lookingFor != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          lookingFor == 'dating' ? Icons.favorite : Icons.people, 
                          color: Colors.white.withOpacity(0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LOOKING FOR ${lookingFor!.toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.white.withOpacity(0.7), 
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildBackgroundImage() {
    if (localImageBytes != null) {
      return Image.memory(
        localImageBytes!,
        fit: BoxFit.cover,
      );
    }
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      return Image.file(
        File(localImagePath!),
        fit: BoxFit.cover,
      );
    }
    if (networkImageUrl != null && networkImageUrl!.isNotEmpty) {
      return AppImage(
        url: networkImageUrl!,
        fit: BoxFit.cover,
        isThumbnail: true,
      );
    }
    return Center(
      child: Icon(Icons.person, size: 80, color: AppColors.inkBlack.withOpacity(0.2)),
    );
  }
}

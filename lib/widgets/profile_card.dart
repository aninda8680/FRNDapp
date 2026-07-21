import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 480,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.lineBlack,
            offset: Offset(4, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
              height: 250,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 3. Info Overlay
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Department & Year
                  Row(
                    children: [
                      const Icon(Icons.school_outlined, size: 20, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$school • $course',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  
                  // Tags
                  if (hobbies.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hobbies.take(3).map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white30, width: 1),
                        ),
                        child: Text(
                          e, 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                      )).toList(),
                    ),
                  ],
                  
                  // Bio
                  const SizedBox(height: 16),
                  Text(
                    '"$bio"',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Preference
                  if (lookingFor != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          lookingFor == 'dating' ? Icons.favorite : Icons.people, 
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Looking for $lookingFor',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
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
    );
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
      return Image.network(
        networkImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.person, size: 80, color: AppColors.lineBlack),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.person, size: 80, color: AppColors.lineBlack),
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_image.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.inkBlack),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => Navigator.pushNamed(context, '/report_block'),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium edge-to-edge image
            Container(
              height: 480,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                child: const AppImage(
                  url: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Age
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SAM, 19', 
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.inkBlack,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      // Level or badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.inkBlack,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Lv. 19',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.cream,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Art Major • New York', 
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.inkBlack.withOpacity(0.6),
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Divider(color: AppColors.inkBlack.withOpacity(0.1), thickness: 1),
                  const SizedBox(height: 32),
                  
                  // About Section
                  Text(
                    'ABOUT ME', 
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.inkBlack.withOpacity(0.5),
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'I love drawing and drinking too much coffee. Always looking for new inspiration in the city, exploring art galleries and hidden cafes.', 
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.inkBlack.withOpacity(0.85),
                      height: 1.6,
                      fontSize: 16,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Interests Section
                  Text(
                    'INTERESTS', 
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.inkBlack.withOpacity(0.5),
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ['Anime', 'Art', 'Coffee', 'Design', 'Photography'].map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.inkBlack.withOpacity(0.15), width: 1.5),
                      ),
                      child: Text(
                        e, 
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkBlack,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/chats/individual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.inkBlack,
                        foregroundColor: AppColors.cream,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'SEND MESSAGE',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.cream,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

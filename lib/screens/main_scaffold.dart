import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home/discover_feed_screen.dart';
import 'matches/likes_matches_screen.dart';
import 'chats/chat_list_screen.dart';
import 'campus/campus_events_screen.dart';
import 'profile/my_profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DiscoverFeedScreen(),
    LikesMatchesScreen(),
    ChatListScreen(),
    CampusEventsScreen(),
    MyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16, top: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cream.withOpacity(0.85),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF6B1B35).withOpacity(0.8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(Icons.style_outlined, Icons.style, 0),
                      _buildNavItem(Icons.favorite_outline, Icons.favorite, 1),
                      _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 2),
                      _buildNavItem(Icons.map_outlined, Icons.map, 3),
                      _buildNavItem(Icons.person_outline, Icons.person, 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF6B1B35) : const Color(0xFF9E9E9E);
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            // Active dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              width: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

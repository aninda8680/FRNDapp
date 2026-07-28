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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DiscoverFeedScreen(),
      const LikesMatchesScreen(),
      const ChatListScreen(),
      const CampusEventsScreen(),
      const MyProfileScreen(),
    ];
  }

  void _onTabSelected(int index) {
    // Auto-refresh chat list whenever user switches to Chats tab
    if (index == 2) {
      ChatListScreen.triggerRefresh?.call();
    }
    setState(() => _currentIndex = index);
  }

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
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black, // Proper black
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    );
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, int index) {
    final isSelected = _currentIndex == index;
    
    // Burgundy when selected, slightly lighter dark grey when unselected
    final bgColor = isSelected ? const Color(0xFFA41534) : const Color(0xFF2A2A2A);
    final iconColor = Colors.white;
    
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? filledIcon : outlineIcon,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }
}

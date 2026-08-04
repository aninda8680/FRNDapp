import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home/discover_feed_screen.dart';
import 'matches/likes_matches_screen.dart';
import 'chats/chat_list_screen.dart';
import 'campus/campus_events_screen.dart';
import 'profile/my_profile_screen.dart';
import '../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
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

  String? get _userPhotoUrl {
    final profile = AuthService.userProfile;
    if (profile != null && profile['pictures'] != null) {
      final pics = profile['pictures'] as List;
      if (pics.isNotEmpty && pics[0] is Map) {
        return pics[0]['url'] as String?;
      }
    }
    return null;
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, int index) {
    final isSelected = _currentIndex == index;
    
    // Burgundy when selected, slightly lighter dark grey when unselected
    final bgColor = isSelected ? const Color(0xFFA41534) : const Color(0xFF2A2A2A);
    final iconColor = Colors.white;
    final hasPhoto = index == 4 && _userPhotoUrl != null;
    
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: hasPhoto ? EdgeInsets.zero : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: hasPhoto
            ? Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.white, width: 2.0) : null,
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: _userPhotoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[800]),
                    errorWidget: (context, url, error) => Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        isSelected ? filledIcon : outlineIcon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              )
            : Icon(
                isSelected ? filledIcon : outlineIcon,
                color: iconColor,
                size: 24,
              ),
      ),
    );
  }
}

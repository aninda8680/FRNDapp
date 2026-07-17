import 'package:flutter/material.dart';
import '../widgets/sketchy_icon_button.dart';
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          border: Border(top: BorderSide(color: AppColors.lineBlack, width: 2)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SketchyIconButton(
                icon: Icons.style,
                isSelected: _currentIndex == 0,
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              SketchyIconButton(
                icon: Icons.favorite,
                isSelected: _currentIndex == 1,
                onPressed: () => setState(() => _currentIndex = 1),
              ),
              SketchyIconButton(
                icon: Icons.chat_bubble,
                isSelected: _currentIndex == 2,
                onPressed: () => setState(() => _currentIndex = 2),
              ),
              SketchyIconButton(
                icon: Icons.map,
                isSelected: _currentIndex == 3,
                onPressed: () => setState(() => _currentIndex = 3),
              ),
              SketchyIconButton(
                icon: Icons.person,
                isSelected: _currentIndex == 4,
                onPressed: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

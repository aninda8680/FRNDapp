import 'package:flutter/material.dart';

class CampusEventsScreen extends StatelessWidget {
  const CampusEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color burgundy = Color(0xFFA41534);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 64,
                color: burgundy.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'Campus Quests',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF040404),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Will add soon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


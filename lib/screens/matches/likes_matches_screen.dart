import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/matches_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../chats/individual_chat_screen.dart';
import '../../widgets/profile_card.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../chats/chat_list_screen.dart';
import 'dart:ui' as ui;
import '../profile/subscription_screen.dart';

class LikesMatchesScreen extends StatefulWidget {
  const LikesMatchesScreen({super.key});

  @override
  State<LikesMatchesScreen> createState() => _LikesMatchesScreenState();
}

class _LikesMatchesScreenState extends State<LikesMatchesScreen> {
  static const Color _burgundy = Color(0xFFA41534);
  static const Color _bgCream = Color(0xFFFDF4E5);

  int _likesCount = 0;
  bool _hasAccess = false;
  List<Map<String, dynamic>> _likers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
    
    // Listen for real-time WebSocket match notification
    ChatService.onNewMatch = (data) {
      if (mounted) {
        print('LikesMatchesScreen: Real-time new_match received: $data');
        _fetchMatches();
        ChatListScreen.triggerRefresh?.call();
      }
    };
  }

  Future<void> _fetchMatches() async {
    setState(() => _isLoading = true);
    
    final likesData = await MatchesService.getIncomingLikes();

    if (mounted) {
      setState(() {
        _likesCount = likesData['totalLikesCount'] ?? 0;
        _hasAccess = likesData['hasAccess'] ?? false;
        
        if (likesData['likers'] != null) {
          final likersList = likesData['likers'] as List<dynamic>;
          _likers = likersList.map((e) => e as Map<String, dynamic>).toList();
        } else {
          _likers = [];
        }
        
        _isLoading = false;
      });
    }
  }

  /// Likes a user back and refreshes if a match is formed
  Future<void> _likeBack(String targetId, String targetName, Map<String, dynamic> partnerProfile) async {
    try {
      final res = await MatchesService.likeUser(targetId);

      if (!mounted) return;

      if (res != null && res['success'] == true) {
        final bool matchFormed = res['matchFormed'] == true;
        final String? conversationId = res['conversationId'] as String?;

        // Refresh data to update incoming likes and matches
        await _fetchMatches();
        ChatListScreen.triggerRefresh?.call();

        if (matchFormed && conversationId != null && conversationId.isNotEmpty) {
          // Instantly unlock 1-on-1 real-time chat via Socket.IO
          ChatService.joinConversation(conversationId);

          if (mounted) {
            showDialog(
              context: context,
              builder: (dialogCtx) => _buildMatchDialog(
                partnerName: targetName,
                conversationId: conversationId,
                partnerProfile: partnerProfile,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text("Sent like to $targetName!"),
                ],
              ),
              backgroundColor: const Color(0xFFA41534),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not like this person. Try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.')),
        );
      }
    }
  }

  Widget _buildMatchDialog({
    required String partnerName,
    required String conversationId,
    required Map<String, dynamic> partnerProfile,
  }) {
    final photoUrl = _getPartnerPhoto(partnerProfile);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA41534).withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA41534), width: 3),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => const Icon(Icons.person, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "IT'S A MATCH! 🎉",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFFA41534),
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "You and $partnerName liked each other!\nReal-time 1-on-1 chat is now unlocked.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withOpacity(0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close match dialog
                // Instantly open 1-on-1 real-time chat screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IndividualChatScreen(
                      conversationId: conversationId,
                      partner: partnerProfile,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text(
                'START CHATTING NOW',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA41534),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Browsing', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }


  // Get photo from the backend partner object structure
  String _getPartnerPhoto(Map<String, dynamic> partner) {
    if (partner['pictures'] != null && (partner['pictures'] as List).isNotEmpty) {
      final pic = partner['pictures'][0];
      if (pic is Map && pic['url'] != null) {
        return pic['url'] as String;
      }
    }
    // Default fallback avatar based on name hash or just a static image
    return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=800';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 48,
        backgroundColor: _bgCream, elevation: 0, surfaceTintColor: Colors.transparent,
        title: Image.asset(
          'assets/images/matches.png',
          height: 28,
        ),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1.0), child: Container(height: 1.0, color: const Color(0x121A1A1A))),
      ),
      body: RefreshIndicator(
        color: _burgundy,
        backgroundColor: Colors.white,
        onRefresh: _fetchMatches,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Incoming Likes Banner (Free Tier)
              if (_likesCount > 0 && !_hasAccess && !_isLoading) _buildLikesBanner(),

              // Premium Likers List
              if (_hasAccess && _likers.isNotEmpty && !_isLoading) ...[
                const Text(
                  'LIKED YOU',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _burgundy,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 165,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _likers.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _buildLikerCard(_likers[index]);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Content Area (Scrollable space for RefreshIndicator when there are likes)
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _burgundy),
                      )
                    : _likesCount == 0
                        ? _buildEmptyState()
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [],
                          ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 64,
                  color: _burgundy.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No New Likes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'When someone likes your profile, they will appear here.\n\nKeep swiping in Home tab!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 120), // Push it slightly up from nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLikesBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _burgundy.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _burgundy.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _burgundy.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.favorite_rounded, color: _burgundy),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _likesCount == 1 ? 'Someone liked your profile' : '$_likesCount people liked you',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep swiping to find out who!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLikerCard(Map<String, dynamic> liker) {
    final bool isLocked = liker['isLocked'] == true || liker['hasAccess'] == false;
    final Map<String, dynamic> profile = Map<String, dynamic>.from(liker['profile'] ?? {});
    final String type = (liker['type'] ?? profile['type'] ?? 'like').toString().toLowerCase();
    final bool isSuperlike = type == 'superlike';
    profile['isSuperlike'] = isSuperlike;
    profile['type'] = type;

    final name = isLocked ? 'Hidden Profile' : (profile['name'] ?? 'Student');
    final targetId = profile['_id'] as String? ?? '';
    final photoUrl = _getPartnerPhoto(profile);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          _showPaywallDialog('Who Liked You?');
          return;
        }
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: ProfileCard(
              name: name,
              age: profile['age']?.toString() ?? '18',
              school: profile['school'] ?? 'Adamas University',
              course: profile['course'] ?? 'CSE',
              bio: profile['bio'] ?? '',
              hobbies: (profile['hobbies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
              lookingFor: profile['lookingFor'],
              networkImageUrl: photoUrl,
              fullProfile: profile,
              onLike: targetId.isNotEmpty ? () => _likeBack(targetId, name, profile) : null,
            ),
          ),
        );
      },
      child: Container(
        width: 128,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSuperlike ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSuperlike ? const Color(0xFF38BDF8) : _burgundy.withOpacity(0.3),
            width: isSuperlike ? 2.0 : 1.5,
          ),
          boxShadow: [
            if (isSuperlike) ...[
              BoxShadow(
                color: const Color(0xFF38BDF8).withOpacity(0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 18,
              ),
            ] else ...[
              BoxShadow(
                color: _burgundy.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SUPERLIKE GLOWING TAG BADGE
            if (isSuperlike)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withOpacity(0.5),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amberAccent, size: 10),
                    SizedBox(width: 2),
                    Text(
                      'SUPER LIKE',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSuperlike ? const Color(0xFF38BDF8) : _bgCream,
                  width: 2,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipOval(
                    child: isLocked 
                      ? ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[200]),
                            errorWidget: (context, url, error) => Container(color: Colors.grey[200]),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) => Container(color: Colors.grey[200]),
                        ),
                  ),
                  if (isLocked)
                    const Center(child: Icon(Icons.lock_rounded, color: Colors.white, size: 28)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSuperlike ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Match / Like Back Button
            if (!isLocked && targetId.isNotEmpty)
              GestureDetector(
                onTap: () => _likeBack(targetId, name, profile),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: isSuperlike
                        ? const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF6366F1)])
                        : null,
                    color: isSuperlike ? null : _burgundy,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSuperlike
                        ? [BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.4), blurRadius: 6)]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSuperlike ? Icons.star_rounded : Icons.favorite,
                        color: isSuperlike ? Colors.amberAccent : Colors.white,
                        size: 10,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isSuperlike ? 'Match' : 'Like Back',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 2),
            Text(
              'View Profile',
              style: TextStyle(
                fontSize: 9,
                color: isSuperlike ? const Color(0xFF38BDF8) : _burgundy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showPaywallDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock, size: 64, color: _burgundy.withOpacity(0.8)),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unlock this profile and see who liked you by upgrading your tier!',
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _burgundy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


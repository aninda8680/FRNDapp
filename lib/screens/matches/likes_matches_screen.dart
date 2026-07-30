import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/matches_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../chats/individual_chat_screen.dart';
import '../../widgets/profile_card.dart';
import '../../services/auth_service.dart';
import '../chats/chat_list_screen.dart';

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
  Future<void> _likeBack(String targetId, String targetName) async {
    try {
      final token = AuthService.token;
      final response = await http.post(
        Uri.parse('https://frnd-api-n3hv.onrender.com/api/like/$targetId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'cookie': token,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Refresh data to move this person to the matches grid
        await _fetchMatches();
        
        // Also refresh chat list in background
        ChatListScreen.triggerRefresh?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text("It's a match with $targetName! 🎉"),
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
        toolbarHeight: 65,
        backgroundColor: _bgCream, elevation: 0, surfaceTintColor: Colors.transparent,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.chat_bubble_rounded, color: _burgundy, size: 20),
          const SizedBox(width: 6),
          Text('MATCHES', style: GoogleFonts.caveat(color: _burgundy, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 26)),
        ]),
        centerTitle: true,
        actions: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset('assets/images/wer-removebg-preview.png', height: 42, fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(height: 2, color: Colors.black)),
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
    final profile = liker['profile'] ?? {};
    final name = profile['name'] ?? 'Student';
    final targetId = profile['_id'] as String? ?? '';
    final photoUrl = _getPartnerPhoto(profile);

    return GestureDetector(
      onTap: () {
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
            ),
          ),
        );
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _burgundy.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _burgundy.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _bgCream, width: 2),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(color: Colors.grey[200]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Like Back Button
            if (targetId.isNotEmpty)
              GestureDetector(
                onTap: () => _likeBack(targetId, name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _burgundy,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: Colors.white, size: 10),
                      SizedBox(width: 3),
                      Text(
                        'Like Back',
                        style: TextStyle(
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
            const Text(
              'View Profile',
              style: TextStyle(
                fontSize: 9,
                color: _burgundy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../../services/matches_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../chats/individual_chat_screen.dart';
import '../../widgets/profile_card.dart';
import '../../services/auth_service.dart';

class LikesMatchesScreen extends StatefulWidget {
  const LikesMatchesScreen({super.key});

  @override
  State<LikesMatchesScreen> createState() => _LikesMatchesScreenState();
}

class _LikesMatchesScreenState extends State<LikesMatchesScreen> {
  static const Color _burgundy = Color(0xFFA41534);
  static const Color _bgCream = Color(0xFFFDF4E5);

  List<Map<String, dynamic>> _matches = [];
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
    if (_matches.isEmpty) {
      setState(() => _isLoading = true);
    }
    
    final results = await Future.wait([
      MatchesService.getMatches(),
      MatchesService.getIncomingLikes(),
    ]);

    if (mounted) {
      setState(() {
        _matches = results[0] as List<Map<String, dynamic>>;
        
        final likesData = results[1] as Map<String, dynamic>;
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
      backgroundColor: Colors.transparent, // Let main scaffold background show
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
              
              // Header Section
              const Text(
                'MUTUAL CONNECTIONS',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _burgundy,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your Matches',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF040404),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Students who liked you back on campus.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

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

              // Content Area (Mutual Matches)
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _burgundy),
                      )
                    : _matches.isEmpty
                        ? _buildEmptyState()
                        : _buildMatchesGrid(),
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
                  'No Matches Yet',
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
                    'Keep swiping in Home tab to find your campus match!\n\n(Pull down to refresh)',
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

  Widget _buildMatchesGrid() {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120), // Space for nav bar
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        final partner = match['partner'] ?? {};
        final name = partner['name'] ?? 'Student';
        final photoUrl = _getPartnerPhoto(partner);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _burgundy, width: 2),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    if (match['conversationId'] != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => IndividualChatScreen(
                            conversationId: match['conversationId'],
                            partner: partner,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot start chat: Missing conversation ID')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _burgundy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'SEND MESSAGE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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


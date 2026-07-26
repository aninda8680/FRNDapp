import 'package:flutter/material.dart';
import '../../services/matches_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LikesMatchesScreen extends StatefulWidget {
  const LikesMatchesScreen({super.key});

  @override
  State<LikesMatchesScreen> createState() => _LikesMatchesScreenState();
}

class _LikesMatchesScreenState extends State<LikesMatchesScreen> {
  static const Color _burgundy = Color(0xFFA41534);
  static const Color _bgCream = Color(0xFFFDF4E5);

  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() => _isLoading = true);
    final matches = await MatchesService.getMatches();
    if (mounted) {
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
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
      body: SafeArea(
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

              // Content Area
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              'Keep swiping in Home tab to find your campus match!',
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
    );
  }

  Widget _buildMatchesGrid() {
    return GridView.builder(
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
                    // Navigate to chat
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
}


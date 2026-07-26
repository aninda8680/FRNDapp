import 'package:flutter/material.dart';
import '../../services/matches_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'individual_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  static const Color _burgundy = Color(0xFFA41534);

  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _filteredMatches = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMatches();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMatches() async {
    setState(() => _isLoading = true);
    final matches = await MatchesService.getMatches();
    if (mounted) {
      setState(() {
        _matches = matches;
        _filteredMatches = matches;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMatches = _matches;
      } else {
        _filteredMatches = _matches.where((m) {
          final partner = m['partner'] ?? {};
          final name = (partner['name'] ?? 'Student').toString().toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  String _getPartnerPhoto(Map<String, dynamic> partner) {
    if (partner['pictures'] != null && (partner['pictures'] as List).isNotEmpty) {
      final pic = partner['pictures'][0];
      if (pic is Map && pic['url'] != null) {
        return pic['url'] as String;
      }
    }
    return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=800';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Header
              const Text(
                'REAL-TIME MESSAGING',
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
                'Campus Chats',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF040404),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black.withOpacity(0.1)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.black.withOpacity(0.4), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search matches...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _burgundy))
                    : _filteredMatches.isEmpty
                        ? _buildEmptyState()
                        : _buildChatList(),
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
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: _burgundy.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Chats',
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
              _searchCtrl.text.isNotEmpty
                  ? 'No matches found matching "${_searchCtrl.text}".'
                  : 'Match with students to unlock direct messaging!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return Container(
      margin: const EdgeInsets.only(bottom: 120), // nav bar spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: _filteredMatches.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: Colors.black.withOpacity(0.05),
          ),
          itemBuilder: (context, index) {
            final match = _filteredMatches[index];
            final partner = match['partner'] ?? {};
            final name = partner['name'] ?? 'Campus Match';
            final photoUrl = _getPartnerPhoto(partner);

            return InkWell(
              onTap: () {
                // For now, navigate to IndividualChatScreen placeholder
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const IndividualChatScreen()),
                );
              },
              highlightColor: Colors.black.withOpacity(0.03),
              splashColor: Colors.black.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _burgundy, width: 1.5),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.person, color: Colors.grey, size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 2),
                          Text(
                            'Matched! Say hi 👋',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Send Arrow
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.send_rounded,
                      color: _burgundy,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/matches_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'individual_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  /// Called by MainScaffold when the Chats tab is tapped — triggers a list refresh.
  static VoidCallback? triggerRefresh;

  @override
  // ignore: library_private_types_in_public_api
  _ChatListRefreshState createState() => _ChatListRefreshState();
}

class _ChatListRefreshState extends State<ChatListScreen> {
  static const Color _cream = Color(0xFFFAF4E1);
  static const Color _inkBlack = Color(0xFF0A0A0A);
  static const Color _crimson = Color(0xFFA31534);

  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _filteredMatches = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ChatListScreen.triggerRefresh = () => _fetchMatches();
    _fetchMatches();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    ChatListScreen.triggerRefresh = null;
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMatches() async {
    if (_matches.isEmpty) {
      setState(() => _isLoading = true);
    }
    final matches = await MatchesService.getMatches();
    
    // Sort matches by time descending (newest first)
    matches.sort((a, b) {
      final aTimeStr = a['lastMessageTime'] as String? ?? a['matchedAt'] as String?;
      final bTimeStr = b['lastMessageTime'] as String? ?? b['matchedAt'] as String?;
      
      if (aTimeStr == null && bTimeStr == null) return 0;
      if (aTimeStr == null) return 1;
      if (bTimeStr == null) return -1;
      
      final aTime = DateTime.tryParse(aTimeStr);
      final bTime = DateTime.tryParse(bTimeStr);
      
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      
      return bTime.compareTo(aTime);
    });

    if (mounted) {
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
      _onSearchChanged(); // Re-apply search filter
    }
  }

  void refresh() => _fetchMatches();

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
      backgroundColor: _cream,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 48,
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          'CAMPUS CHATS',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1.0), child: Container(height: 1.0, color: const Color(0x121A1A1A))),
      ),
      body: Stack(
        children: [
          // Background layer
          Positioned(
            top: -30,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/redTreebg.png',
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              opacity: const AlwaysStoppedAnimation(0.65),
            ),
          ),
          // Status bar gradient for better icon visibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top + 40,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFAF4E1),
                    const Color(0xFFFAF4E1).withOpacity(0.9),
                    const Color(0xFFFAF4E1).withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Layer 1: Skeleton
          if (_isLoading)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Visibility(
                      visible: false,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: _inkBlack, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: TextField(
                                decoration: InputDecoration(isDense: true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(child: _buildSkeletonLoader()),
                  ],
                ),
              ),
            ),

          // Layer 2: Tonight.png
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Transform.translate(
              offset: const Offset(-2, 0), // Moves it left by 40 pixels
              child: Transform.scale(
                scale: 1.6, // 50% bigger!
                alignment: Alignment.bottomCenter, // Keeps it pinned to the navbar
                child: Image.asset(
                  'assets/images/Tonight.png',
                  width: double.infinity,
                  fit: BoxFit.contain,
                  opacity: const AlwaysStoppedAnimation(0.3),
                ),
              ),
            ),
          ),

          // Layer 3: Foreground content
          RefreshIndicator(
            color: _crimson,
            backgroundColor: Colors.white,
            onRefresh: _fetchMatches,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _inkBlack, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: _inkBlack.withOpacity(0.5), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search matches...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 15,
                              color: _inkBlack.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: _inkBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Content Area
                Expanded(
                  child: _isLoading
                      ? const SizedBox() // Show nothing in foreground so background layers show through
                      : _filteredMatches.isEmpty
                          ? _buildEmptyState()
                          : _buildChatList(),
                ),
              ],
            ),
          ),
        ),
      ),
      ],
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
                Text(
                  _searchCtrl.text.isNotEmpty
                      ? 'No matches found matching "${_searchCtrl.text}".'
                      : 'Your matches will appear here',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _inkBlack.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 200),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 120),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 6,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          thickness: 1,
          color: _crimson,
        ),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _inkBlack.withOpacity(0.05),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _inkBlack.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _inkBlack.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.6));
        },
      ),
    );
  }

  Widget _buildChatList() {
    return Container(
      margin: const EdgeInsets.only(bottom: 120), // nav bar spacing
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _filteredMatches.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          thickness: 1,
          color: _crimson,
        ),
        itemBuilder: (context, index) {
          final match = _filteredMatches[index];
          final partner = match['partner'] ?? {};
          final name = partner['name'] ?? 'Campus Match';
          final photoUrl = _getPartnerPhoto(partner);
          
          final lastMessage = match['lastMessage'] as String?;
          final timeStr = match['lastMessageTime'] as String? ?? match['matchedAt'] as String?;
          final isUnread = match['unreadCount'] != null && match['unreadCount'] > 0;
          
          String timeText = '';
          if (timeStr != null) {
            final dt = DateTime.tryParse(timeStr)?.toLocal();
            if (dt != null) {
              final now = DateTime.now();
              final diff = now.difference(dt);
              if (diff.inDays >= 1) {
                timeText = diff.inDays == 1 ? '1d' : '${diff.inDays}d';
              } else if (diff.inHours >= 1) {
                timeText = '${diff.inHours}h';
              } else if (diff.inMinutes >= 1) {
                timeText = '${diff.inMinutes}m';
              } else {
                timeText = 'Now';
              }
            }
          }
          final previewText = lastMessage ?? 'Matched! Say hi 👋';

          return InkWell(
            onTap: () {
              if (match['conversationId'] == null) return;
              
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => IndividualChatScreen(
                    conversationId: match['conversationId'],
                    partner: partner,
                  ),
                ),
              );
            },
            highlightColor: _inkBlack.withOpacity(0.03),
            splashColor: _inkBlack.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _crimson, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(2.0),
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
                  const SizedBox(width: 16),
                  
                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _inkBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          previewText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _inkBlack.withOpacity(isUnread ? 0.8 : 0.5),
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Unread indicator / Timestamp
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isUnread ? _crimson : _inkBlack.withOpacity(0.4),
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _crimson,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

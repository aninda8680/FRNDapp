import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/post_service.dart';
import '../../widgets/top_notification.dart';
import 'campus_compose_screen.dart';

class CampusEventsScreen extends StatefulWidget {
  const CampusEventsScreen({super.key});

  @override
  State<CampusEventsScreen> createState() => _CampusEventsScreenState();
}

class _CampusEventsScreenState extends State<CampusEventsScreen> {
  final Color burgundy = const Color(0xFFA41534);
  bool _isLoading = true;
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final fetched = await PostService.getPosts();
    setState(() {
      _posts = fetched;
      _isLoading = false;
    });
  }

  void _showNotification(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TopNotification(
        message: message,
        backgroundColor: backgroundColor,
        onDismissed: () {
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  Future<void> _submitPost(String text, bool isAnonymous) async {
    final result = await PostService.createPost(text, isAnonymous: isAnonymous);

    if (!mounted) return;

    Navigator.of(context).pop();

    if (result != null) {
      _loadPosts();
      _showNotification(
        isAnonymous ? 'Whisper posted! 🤫' : 'Post shared! 🎉',
        backgroundColor: Colors.green.shade600,
      );
    } else {
      _showNotification(
        'Could not post. You may have hit your daily limit.',
        backgroundColor: burgundy,
      );
    }
  }

  void _showComposeSheet() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CampusComposeScreen(
          burgundy: burgundy,
          onSubmit: _submitPost,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _onVote(int index, bool isUpvote) async {
    final post = _posts[index];
    final String? postId = post['id'] as String?;
    if (postId == null) return;

    final String targetVote = isUpvote ? 'upvote' : 'downvote';
    final String? previousVote = post['userVote'] as String?;
    
    // Calculate optimistic counts
    final bool isRemovingVote = previousVote == targetVote;
    final String? newVote = isRemovingVote ? null : targetVote;

    int newUpvotes = post['upvotesCount'] ?? 0;
    int newDownvotes = post['downvotesCount'] ?? 0;

    // Remove old vote
    if (previousVote == 'upvote') newUpvotes = (newUpvotes - 1).clamp(0, 9999);
    if (previousVote == 'downvote') newDownvotes = (newDownvotes - 1).clamp(0, 9999);

    // Add new vote
    if (newVote == 'upvote') newUpvotes++;
    if (newVote == 'downvote') newDownvotes++;

    // 1. Optimistic UI Update
    setState(() {
      _posts[index] = {
        ...post,
        'upvotesCount': newUpvotes,
        'downvotesCount': newDownvotes,
        'userVote': newVote,
      };
    });

    // 2. Background API Call
    final futureResult = isUpvote
        ? PostService.upvotePost(postId)
        : PostService.downvotePost(postId);

    futureResult.then((result) {
      if (!mounted) return;
      if (result == null) {
        // Revert on failure
        setState(() {
          _posts[index] = post; 
        });
        return;
      }

      // Sync with exact server truth
      setState(() {
        _posts[index] = {
          ..._posts[index],
          'upvotesCount': result['upvotesCount'] ?? post['upvotesCount'] ?? 0,
          'downvotesCount': result['downvotesCount'] ?? post['downvotesCount'] ?? 0,
          'userVote': result['userVote'],
        };
      });
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _posts[index] = post; // Revert on exception
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background layer
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.65,
              child: Image.asset(
                'assets/images/redTreebg.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Center(
                    child: Text(
                      'Anonymous\nWhispers',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A1A1A),
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                // Post list
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: burgundy))
                      : _posts.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadPosts,
                              color: burgundy,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 90, 
                                ),
                                physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics()),
                                itemCount: _posts.length,
                                itemBuilder: (context, index) {
                                  return _PostCard(
                                    post: _posts[index],
                                    burgundy: burgundy,
                                    onUpvote: () => _onVote(index, true),
                                    onDownvote: () => _onVote(index, false),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110, right: 8),
        child: FloatingActionButton(
          onPressed: _showComposeSheet,
          backgroundColor: burgundy,
          shape: const CircleBorder(),
          child: Image.asset(
            'assets/images/write.png',
            width: 34,
            height: 34,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            'No whispers yet.\nBe the first to share a secret!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.black38,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final Color burgundy;
  final Future<void> Function() onUpvote;
  final Future<void> Function() onDownvote;

  const _PostCard({
    required this.post,
    required this.burgundy,
    required this.onUpvote,
    required this.onDownvote,
  });

  @override
  Widget build(BuildContext context) {
    String timeStr = 'Just now';
    if (post['createdAt'] != null) {
      try {
        timeStr = timeago.format(DateTime.parse(post['createdAt']));
      } catch (_) {}
    }

    final bool isAnonymous = post['isAnonymous'] as bool? ?? true;
    final Map<String, dynamic>? author = post['author'] as Map<String, dynamic>?;
    final String content = post['content'] as String? ?? '';
    final int upvotes = post['upvotesCount'] as int? ?? 0;
    final int downvotes = post['downvotesCount'] as int? ?? 0;
    final String? userVote = post['userVote'] as String?;

    final String displayName = isAnonymous
        ? 'Anonymous'
        : (author?['name'] as String? ??
            author?['username'] as String? ??
            'Campus');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnonymous ? burgundy.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.06), 
          width: isAnonymous ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isAnonymous)
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              Text(
                timeStr,
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1A1A1A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _VoteButton(
                icon: Icons.arrow_upward_rounded,
                count: upvotes,
                active: userVote == 'upvote',
                activeColor: Colors.green.shade600,
                onTap: onUpvote,
              ),
              const SizedBox(width: 12),
              _VoteButton(
                icon: Icons.arrow_downward_rounded,
                count: downvotes,
                active: userVote == 'downvote',
                activeColor: burgundy,
                onTap: onDownvote,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatefulWidget {
  final IconData icon;
  final int count;
  final bool active;
  final Color activeColor;
  final Future<void> Function() onTap;

  const _VoteButton({
    required this.icon,
    required this.count,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<_VoteButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isLoading) return;
        setState(() => _isLoading = true);
        await widget.onTap();
        if (mounted) setState(() => _isLoading = false);
      },
      child: AnimatedScale(
        scale: _isLoading ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.active
                ? widget.activeColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.active ? widget.activeColor : Colors.black38,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.count}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.active ? widget.activeColor : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

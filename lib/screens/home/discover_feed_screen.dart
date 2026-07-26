import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../services/discover_service.dart';

// ─── Color tokens ──────────────────────────────────────────────────────────
const _bgCream = Color(0xFFFDF4E5);
const _burgundy = Color(0xFFA41534);
const _darkBurgundy = Color(0xFF8A0F26);
const _gold = Color(0xFFFFD700);

class DiscoverFeedScreen extends StatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _profiles = [];
  int _currentIndex = 0;
  int _page = 1;
  bool _isLoading = true;
  bool _hasMore = true;
  int _cardPhotoIndex = 0;

  // ─── Details sheet animation ───────────────────────────────────────────
  late AnimationController _detailsCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _cardScaleAnim;
  bool get _detailsVisible => _detailsCtrl.value > 0.0;

  void _openDetails() {
    _detailsCtrl.animateTo(1.0,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic);
  }

  void _closeDetails() {
    _detailsCtrl.animateTo(0.0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInCubic);
  }

  @override
  void initState() {
    super.initState();
    _detailsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _detailsCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _detailsCtrl, curve: Curves.easeOut),
    );
    _cardScaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _detailsCtrl, curve: Curves.easeOutCubic),
    );
    _fetchFeed(reset: true);
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchFeed({bool reset = false}) async {
    if (!_hasMore && !reset) return;
    setState(() => _isLoading = true);
    if (reset) {
      _page = 1;
      _hasMore = true;
    }
    final profiles = await DiscoverService.getFeed(page: _page, limit: 15);
    setState(() {
      if (reset) {
        _profiles = profiles;
        _currentIndex = 0;
      } else {
        _profiles.addAll(profiles);
      }
      if (profiles.isEmpty) _hasMore = false;
      _page++;
      _isLoading = false;
    });
  }

  Map<String, dynamic>? get _currentProfile =>
      (_profiles.isNotEmpty && _currentIndex < _profiles.length)
          ? _profiles[_currentIndex]
          : null;

  Future<void> _onAction(String action) async {
    final profile = _currentProfile;
    if (profile == null) return;
    final id = profile['_id'] as String? ?? '';

    // Fire-and-forget API calls for non-mock IDs
    if (!id.startsWith('mock')) {
      if (action == 'like') DiscoverService.likeProfile(id);
      if (action == 'pass') DiscoverService.passProfile(id);
      if (action == 'superlike') DiscoverService.superlikeProfile(id);
    }

    // Close details if open, then advance
    if (_detailsVisible) {
      await _detailsCtrl.animateTo(0.0,
          duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
    }

    setState(() {
      _cardPhotoIndex = 0;
      _currentIndex++;
    });

    // Load more if near end
    if (_currentIndex >= _profiles.length - 3 && _hasMore && !_isLoading) {
      _fetchFeed();
    }
  }

  String _getPhoto(Map<String, dynamic>? profile, {int photoIndex = 0}) {
    if (profile == null) return '';
    final pics = profile['pictures'] as List<dynamic>?;
    if (pics != null && pics.isNotEmpty) {
      final idx = photoIndex % pics.length;
      final item = pics[idx];
      if (item is Map) return item['url']?.toString() ?? '';
      if (item is String) return item;
    }
    // Fallback
    final id = profile['_id']?.toString() ?? '0';
    final fallbacks = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&q=80',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&q=80',
    ];
    return fallbacks[id.codeUnitAt(0) % fallbacks.length];
  }

  int _getPhotoCount(Map<String, dynamic>? profile) {
    if (profile == null) return 1;
    final pics = profile['pictures'] as List<dynamic>?;
    return (pics != null && pics.isNotEmpty) ? pics.length : 1;
  }

  String _formatHeight(dynamic cm) {
    if (cm == null) return '';
    final c = (cm as num).toInt();
    final total = c / 2.54;
    final ft = total ~/ 12;
    final inch = (total % 12).round();
    return "$c cm ($ft'$inch\")";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream.withOpacity(0.95),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, color: _burgundy, size: 20),
            const SizedBox(width: 6),
            const Text(
              'DISCOVER',
              style: TextStyle(
                color: _burgundy,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.black.withOpacity(0.08)),
        ),
      ),
      body: _isLoading && _profiles.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _burgundy),
                  SizedBox(height: 16),
                  Text(
                    'LOADING PROFILES...',
                    style: TextStyle(
                      color: _burgundy,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            )
          : _currentProfile == null
              ? _buildEmptyState()
              : AnimatedBuilder(
                  animation: _detailsCtrl,
                  builder: (context, _) {
                    return Stack(
                      children: [
                        // Card — scales down slightly when details are open
                        Transform.scale(
                          scale: _cardScaleAnim.value,
                          alignment: Alignment.topCenter,
                          child: _buildCardStack(),
                        ),

                        // Dark scrim backdrop
                        if (_detailsVisible)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: _closeDetails,
                              child: Container(
                                color: Colors.black.withOpacity(_fadeAnim.value),
                              ),
                            ),
                          ),

                        // Sliding full-profile sheet
                        if (_detailsVisible && _currentProfile != null)
                          SlideTransition(
                            position: _slideAnim,
                            child: _buildFullDetailsSheet(),
                          ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _burgundy.withOpacity(0.12),
              ),
              child: const Icon(Icons.auto_awesome, color: _burgundy, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'No More Profiles',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF040404)),
            ),
            const SizedBox(height: 8),
            const Text(
              "You've seen all verified students in your area.\nChange filters or check back later!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchFeed(reset: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('REFRESH FEED'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _burgundy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack() {
    final bottomPad = MediaQuery.of(context).padding.bottom + 16;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
            child: _SwipeCard(
              key: ValueKey('${_currentProfile!['_id']}_$_currentIndex'),
              profile: _currentProfile!,
              currentPhotoIndex: _cardPhotoIndex,
              photoCount: _getPhotoCount(_currentProfile),
              getPhoto: (idx) => _getPhoto(_currentProfile, photoIndex: idx),
              formatHeight: _formatHeight,
              onPhotoChange: (idx) => setState(() => _cardPhotoIndex = idx),
              onAction: _onAction,
              onShowDetails: _openDetails,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullDetailsSheet() {
    final profile = _currentProfile!;
    final photoCount = _getPhotoCount(profile);

    return Material(
      color: Colors.transparent,
      child: Container(
          color: const Color(0xFFFFF5E9),
          child: SafeArea(
            child: Column(
              children: [
                // Header bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5E9).withOpacity(0.97),
                    border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.08))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'STUDENT PROFILE',
                        style: TextStyle(
                          color: _burgundy,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      GestureDetector(
                        onTap: _closeDetails,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo 1
                        _detailPhoto(_getPhoto(profile, photoIndex: 0)),

                        const SizedBox(height: 16),

                        // Name & vitals card
                        _detailCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${profile['name']}, ${profile['age']}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF040404),
                                    ),
                                  ),
                                  if (profile['identityStatus'] == 'verified') ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.verified, color: _burgundy, size: 22),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (profile['height'] != null)
                                    _chip(
                                      '${_formatHeight(profile['height'])}',
                                      icon: Icons.straighten_rounded,
                                    ),
                                  if (profile['sexualOrientation'] != null)
                                    _chip('${profile['sexualOrientation']}'),
                                  if (profile['lookingFor'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: _burgundy,
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: Text(
                                        (profile['lookingFor'] as String).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Photo 2
                        if (photoCount > 1) ...[
                          const SizedBox(height: 16),
                          _detailPhoto(_getPhoto(profile, photoIndex: 1)),
                        ],

                        // School & Course
                        if (profile['school'] != null || profile['course'] != null) ...[
                          const SizedBox(height: 16),
                          _detailCard(
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _burgundy.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _burgundy.withOpacity(0.3)),
                                  ),
                                  child: const Icon(Icons.school_rounded, color: _burgundy, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'UNIVERSITY & COURSE',
                                        style: TextStyle(color: _burgundy, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        profile['school'] ?? 'Campus Student',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF040404)),
                                      ),
                                      if (profile['course'] != null)
                                        Text(
                                          profile['course'],
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Photo 3
                        if (photoCount > 2) ...[
                          const SizedBox(height: 16),
                          _detailPhoto(_getPhoto(profile, photoIndex: 2)),
                        ],

                        // Bio
                        if (profile['bio'] != null && (profile['bio'] as String).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _detailCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ABOUT ME',
                                  style: TextStyle(color: _burgundy, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '"${profile['bio']}"',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF040404),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Hobbies & Skills
                        if ((profile['hobbies'] as List?)?.isNotEmpty == true ||
                            (profile['skills'] as List?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 16),
                          _detailCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'INTERESTS & HOBBIES',
                                  style: TextStyle(color: _burgundy, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ...?(profile['hobbies'] as List?)?.map((h) => _hobbyChip(h.toString())),
                                    ...?(profile['skills'] as List?)?.map((s) => _hobbyChip(s.toString())),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Sticky bottom action buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    border: Border(top: BorderSide(color: Colors.black.withOpacity(0.08))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onAction('pass'),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('PASS'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.black.withOpacity(0.15)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _onAction('like'),
                          icon: const Icon(Icons.favorite_rounded, size: 16),
                          label: const Text('LIKE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _burgundy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _detailPhoto(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: url.isNotEmpty
            ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.person, size: 80, color: Colors.grey))
            : const Icon(Icons.person, size: 80, color: Colors.grey),
      ),
    );
  }

  Widget _detailCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _chip(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _bgCream,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: _burgundy), const SizedBox(width: 4)],
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _hobbyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _bgCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.label_outline_rounded, size: 13, color: _burgundy),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Swipeable Card Widget ─────────────────────────────────────────────────
class _SwipeCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final int currentPhotoIndex;
  final int photoCount;
  final String Function(int) getPhoto;
  final String Function(dynamic) formatHeight;
  final void Function(int) onPhotoChange;
  final void Function(String) onAction;
  final VoidCallback onShowDetails;

  const _SwipeCard({
    Key? key,
    required this.profile,
    required this.currentPhotoIndex,
    required this.photoCount,
    required this.getPhoto,
    required this.formatHeight,
    required this.onPhotoChange,
    required this.onAction,
    required this.onShowDetails,
  }) : super(key: key);

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> with SingleTickerProviderStateMixin {
  Offset _drag = Offset.zero;
  late AnimationController _animCtrl;
  Animation<Offset>? _snapAnim;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _animCtrl.addListener(() {
      if (_snapAnim != null) setState(() => _drag = _snapAnim!.value);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_animating) return;
    setState(() => _drag += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_animating) return;
    // Swipe up → show full profile details
    if (_drag.dy < -80 && _drag.dx.abs() < 80) {
      _snapBack();
      widget.onShowDetails();
      return;
    }
    if (_drag.dx > 100) {
      _animateOut(const Offset(1000, 100), 'like');
    } else if (_drag.dx < -100) {
      _animateOut(const Offset(-1000, 100), 'pass');
    } else {
      _snapBack();
    }
  }

  void _animateOut(Offset target, String action) {
    _animating = true;
    _snapAnim = Tween<Offset>(begin: _drag, end: target).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward(from: 0).then((_) {
      widget.onAction(action);
    });
  }

  void _snapBack() {
    _snapAnim = Tween<Offset>(begin: _drag, end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
    );
    _animCtrl.forward(from: 0).then((_) {
      setState(() {
        _drag = Offset.zero;
        _animating = false;
      });
    });
  }

  void _triggerAction(String action) {
    if (_animating) return;
    final target = action == 'pass'
        ? const Offset(-1000, 100)
        : action == 'superlike'
            ? const Offset(0, -1000)
            : const Offset(1000, 100);
    _animateOut(target, action);
  }

  @override
  Widget build(BuildContext context) {
    final rotation = _drag.dx / 1200 * (math.pi / 6);
    // Only show like/pass labels on horizontal drag; suppress on vertical swipe-up
    final isVertical = _drag.dy.abs() > _drag.dx.abs();
    final likeOpacity = isVertical ? 0.0 : (_drag.dx / 120).clamp(0.0, 1.0);
    final passOpacity = isVertical ? 0.0 : (-_drag.dx / 120).clamp(0.0, 1.0);
    // Show a subtle "swipe up" hint when dragging upward
    final swipeUpOpacity = ((-_drag.dy - 20) / 60).clamp(0.0, 1.0) * (isVertical ? 1.0 : 0.0);
    final profile = widget.profile;
    final photoUrl = widget.getPhoto(widget.currentPhotoIndex);

    return Transform.translate(
      offset: _drag,
      child: Transform.rotate(
        angle: rotation,
        child: GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Colors.black,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Photo ──────────────────────────────────────────────
                  photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ColoredBox(color: Colors.black12),
                          errorWidget: (_, __, ___) => const ColoredBox(
                            color: Color(0xFF1A1A1A),
                            child: Icon(Icons.person, size: 80, color: Colors.white30),
                          ),
                        )
                      : const ColoredBox(color: Color(0xFF1A1A1A)),

                  // ── Gradient overlay ───────────────────────────────────
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xFF000000),
                          Color(0x88000000),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.35, 0.65, 1.0],
                      ),
                    ),
                  ),

                  // ── Photo indicator bars ───────────────────────────────
                  if (widget.photoCount > 1)
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: List.generate(widget.photoCount, (i) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: i == widget.currentPhotoIndex
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.35),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  // ── Like / Pass labels ─────────────────────────────────
                  if (likeOpacity > 0.05)
                    Positioned(
                      top: 50,
                      left: 20,
                      child: Opacity(
                        opacity: likeOpacity.clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 2.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('LIKE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2)),
                        ),
                      ),
                    ),

                  if (passOpacity > 0.05)
                    Positioned(
                      top: 50,
                      right: 20,
                      child: Opacity(
                        opacity: passOpacity.clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.redAccent, width: 2.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('NOPE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2)),
                        ),
                      ),
                    ),

                  // ── Tap zones for photo switching ──────────────────────
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 180,
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              if (widget.currentPhotoIndex > 0) {
                                widget.onPhotoChange(widget.currentPhotoIndex - 1);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              if (widget.currentPhotoIndex < widget.photoCount - 1) {
                                widget.onPhotoChange(widget.currentPhotoIndex + 1);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Profile info ───────────────────────────────────────
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: widget.onShowDetails,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${profile['name'] ?? ''}, ${profile['age'] ?? ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                                  ),
                                ),
                              ),
                              if (profile['identityStatus'] == 'verified') ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.verified_rounded, color: _burgundy, size: 22, shadows: [Shadow(color: Colors.white, blurRadius: 4)]),
                              ],
                            ],
                          ),
                          if (profile['school'] != null || profile['course'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.school_rounded, color: _burgundy, size: 15),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    '${profile['school'] ?? ''} ${profile['course'] != null ? '(${profile['course']})' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (profile['bio'] != null && (profile['bio'] as String).isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              '"${profile['bio']}"',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (profile['height'] != null)
                                _infoChip(
                                  text: widget.formatHeight(profile['height']),
                                  icon: Icons.straighten_rounded,
                                ),
                              if (profile['lookingFor'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _burgundy,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (profile['lookingFor'] as String).toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Swipe-up dynamic feedback label ────────────────────
                  if (swipeUpOpacity > 0.0)
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: swipeUpOpacity.clamp(0.0, 1.0),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.person_search_rounded, color: _burgundy, size: 16),
                                SizedBox(width: 6),
                                Text('SEE FULL PROFILE', style: TextStyle(color: _burgundy, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Swipe-up pill hint (always visible) ───────────────
                  Positioned(
                    bottom: 95,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white70, size: 14),
                            SizedBox(width: 3),
                            Text('swipe up for more', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _actionBtn(
                          icon: Icons.close_rounded,
                          bgColor: Colors.white.withOpacity(0.92),
                          fgColor: Colors.black87,
                          size: 58,
                          onTap: () => _triggerAction('pass'),
                        ),
                        const SizedBox(width: 18),
                        _actionBtn(
                          icon: Icons.star_rounded,
                          bgColor: _gold,
                          fgColor: Colors.black,
                          size: 48,
                          onTap: () => _triggerAction('superlike'),
                        ),
                        const SizedBox(width: 18),
                        _actionBtn(
                          icon: Icons.favorite_rounded,
                          bgColor: _burgundy,
                          fgColor: Colors.white,
                          size: 58,
                          onTap: () => _triggerAction('like'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Icon(icon, color: fgColor, size: size * 0.45),
      ),
    );
  }
}

Widget _infoChip({required String text, IconData? icon}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.22),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, color: _burgundy, size: 11), const SizedBox(width: 4)],
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

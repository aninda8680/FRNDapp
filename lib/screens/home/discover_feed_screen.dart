import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../services/discover_service.dart';
import '../../widgets/full_profile_sheet.dart';
import '../chats/individual_chat_screen.dart';
import '../profile/subscription_screen.dart';

const _bgCream = Color(0xFFFDF4E5);
const _burgundy = Color(0xFFA41534);
const _gold = Color(0xFFFFD700);

class _NetBasketController {
  _NetBasketWidgetState? _state;
  void _attach(_NetBasketWidgetState s) => _state = s;
  void _detach() => _state = null;
  void triggerCatch({required bool isSuperlike}) => _state?._triggerCatch(isSuperlike: isSuperlike);
}

class _NetMeshPainter extends CustomPainter {
  final double deformFactor;
  final bool isSuperlike;
  final double swayPhase;
  final double sparkleProgress;

  const _NetMeshPainter({
    required this.deformFactor,
    required this.isSuperlike,
    required this.swayPhase,
    this.sparkleProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool active = deformFactor > 0.02;
    final Color rimColor = Colors.black;
    final Color meshColor = Colors.black;

    final double cx = size.width / 2;
    const double rimY = 30.0;
    
    final bgRect = Rect.fromCenter(center: Offset(cx, rimY - 10), width: size.width * 0.28, height: 75);
    final bgRRect = RRect.fromRectAndRadius(bgRect, const Radius.circular(12));
    final Color burgundyColor = const Color(0xFFA41534);
    canvas.drawRRect(bgRRect, Paint()..color = burgundyColor.withOpacity(0.35));
    canvas.drawRRect(bgRRect, Paint()..style = PaintingStyle.stroke..color = burgundyColor.withOpacity(0.7)..strokeWidth = 2.5);

    final innerRect = Rect.fromCenter(center: Offset(cx, rimY - 5), width: size.width * 0.12, height: 40);
    canvas.drawRect(innerRect, Paint()..style = PaintingStyle.stroke..color = burgundyColor.withOpacity(0.6)..strokeWidth = 2);

    const cols = 8;
    const rows = 5;
    const mH = 55.0;
    final df = deformFactor.clamp(0.0, 2.0);

    final hoopRect = Rect.fromCenter(center: Offset(cx, rimY + 12), width: size.width * 0.16, height: 22);

    final pts = <List<Offset>>[];
    for (int r = 0; r <= rows; r++) {
      final row = <Offset>[];
      for (int c = 0; c <= cols; c++) {
        double t = c / cols;
        double angle = math.pi + t * math.pi;
        
        double xBase, yBase;
        if (r == 0) {
          xBase = cx + (hoopRect.width / 2) * math.cos(angle);
          yBase = hoopRect.center.dy + (hoopRect.height / 2) * math.sin(angle);
        } else {
          double startX = cx + (hoopRect.width / 2) * math.cos(angle);
          double endX = cx + (hoopRect.width / 3.5) * math.cos(angle);
          xBase = ui.lerpDouble(startX, endX, r / rows)!;
          double startY = hoopRect.center.dy + (hoopRect.height / 2) * math.sin(angle);
          yBase = startY + (r / rows) * mH;
        }

        double x = xBase + math.sin(swayPhase + c * 0.6) * 1.5;
        double y = yBase + math.sin(swayPhase * 0.8 + r * 1.0) * 0.5;

        if (df > 0.001) {
          final cxNorm = (c / cols) - 0.5;
          final crNorm = r / rows;
          final falloff = math.exp(-cxNorm * cxNorm * 10.0);
          y += df * falloff * crNorm * 28.0;
          x += df * cxNorm * falloff * crNorm * -10.0;
        }
        row.add(Offset(x, y));
      }
      pts.add(row);
    }

    final meshPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..strokeCap = StrokeCap.round..color = meshColor;
    for (int r = 1; r <= rows; r++) {
      final path = Path()..moveTo(pts[r][0].dx, pts[r][0].dy);
      for (int c = 1; c <= cols; c++) path.lineTo(pts[r][c].dx, pts[r][c].dy);
      canvas.drawPath(path, meshPaint);
    }
    for (int c = 0; c <= cols; c++) {
      final path = Path()..moveTo(pts[0][c].dx, pts[0][c].dy);
      for (int r = 1; r <= rows; r++) path.lineTo(pts[r][c].dx, pts[r][c].dy);
      canvas.drawPath(path, meshPaint);
    }

    final rimPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 4.5..color = rimColor;
    canvas.drawOval(hoopRect, rimPaint);

    if (isSuperlike && sparkleProgress > 0 && sparkleProgress < 1.0) {
      _paintSparkles(canvas, size, sparkleProgress);
    } else if (active && sparkleProgress > 0 && sparkleProgress < 1.0) {
      _paintSwish(canvas, size, sparkleProgress);
    }
  }

  void _paintSwish(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    final cy = 42.0;
    final paint = Paint()..color = _burgundy.withOpacity((1.0 - t).clamp(0.0, 1.0))..strokeWidth = 2..style = PaintingStyle.stroke;
    for(int i = 0; i < 5; i++) {
      final dx = (i - 2) * 12.0;
      final dy = t * 40.0 + (i % 2) * 10.0;
      canvas.drawLine(Offset(cx + dx, cy + dy), Offset(cx + dx, cy + dy + 8), paint);
    }
  }

  void _paintSparkles(Canvas canvas, Size size, double t) {
    final center = Offset(size.width / 2, 42);
    const count = 36;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + (i.isEven ? 0.3 : -0.3);
      final expansion = 150.0 + (i % 4) * 100.0;
      final dist = 30.0 + expansion * math.pow(t, 0.6);
      final pos = Offset(center.dx + math.cos(angle) * dist, center.dy + math.sin(angle) * dist);
      final r = (5.0 + (i % 3) * 2.5) * (1.0 - t);
      final opacity = (1.0 - t * 1.2).clamp(0.0, 1.0);
      
      final path = Path();
      const points = 5;
      final outerR = r * 2.5;
      final innerR = r * 1.0;
      
      // Give each star a slight rotation based on its index and expansion
      final rotation = angle + t * (i.isEven ? 2.0 : -2.0);
      
      for (int j = 0; j < points * 2; j++) {
        final radius = j.isEven ? outerR : innerR;
        final theta = rotation + (j * math.pi / points) - math.pi / 2;
        final px = pos.dx + radius * math.cos(theta);
        final py = pos.dy + radius * math.sin(theta);
        if (j == 0) path.moveTo(px, py);
        else path.lineTo(px, py);
      }
      path.close();
      
      // Draw a burgundy star with a slight white glow/core
      canvas.drawPath(path, Paint()..color = const Color(0xFFA41534).withOpacity(opacity));
      canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(opacity * 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    }
  }

  @override
  bool shouldRepaint(_NetMeshPainter old) =>
      old.deformFactor != deformFactor || old.isSuperlike != isSuperlike ||
      old.swayPhase != swayPhase || old.sparkleProgress != sparkleProgress;
}

class _NetBasketWidget extends StatefulWidget {
  final _NetBasketController controller;
  const _NetBasketWidget({super.key, required this.controller});
  @override
  State<_NetBasketWidget> createState() => _NetBasketWidgetState();
}

class _NetBasketWidgetState extends State<_NetBasketWidget> with TickerProviderStateMixin {
  AnimationController? _springCtrl;
  double _deformFactor = 0.0;
  bool _isSuperlike = false;
  AnimationController? _sparkleCtrl;
  double _sparkleProgress = 0.0;
  double _shakeOffset = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void dispose() {
    widget.controller._detach();
    _springCtrl?.dispose();
    _sparkleCtrl?.dispose();
    super.dispose();
  }

  void _triggerCatch({required bool isSuperlike}) {
    setState(() => _isSuperlike = isSuperlike);
    _springCtrl?.dispose();
    _springCtrl = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (mounted) setState(() {
          _deformFactor = _springCtrl!.value;
          _shakeOffset = math.sin(_deformFactor * math.pi * 4) * 2.0; 
        });
      });
    const spring = SpringDescription(mass: 1.0, stiffness: 220.0, damping: 10.0);
    _springCtrl!.animateWith(SpringSimulation(spring, 0.0, 1.0, 12.0));
    
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() { _deformFactor = 0.0; _isSuperlike = false; _shakeOffset = 0.0; });
    });

    _sparkleCtrl?.dispose();
    _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..addListener(() { if (mounted) setState(() => _sparkleProgress = _sparkleCtrl!.value); })
      ..addStatusListener((s) { if (s == AnimationStatus.completed) setState(() => _sparkleProgress = 0.0); })
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120, width: double.infinity,
      child: Transform.translate(
        offset: Offset(0, _shakeOffset),
        child: CustomPaint(
          painter: _NetMeshPainter(
            deformFactor: _deformFactor, isSuperlike: _isSuperlike,
            swayPhase: 0.0, sparkleProgress: _sparkleProgress,
          ),
        ),
      ),
    );
  }
}

class _DustbinController extends ChangeNotifier {
  late AnimationController animCtrl;
  double wobble = 0.0;
  double poof = 0.0;

  void init(TickerProvider vsync) {
    animCtrl = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 650));
    animCtrl.addListener(() {
      final v = animCtrl.value;
      // Wobble: damped sine wave
      wobble = math.sin(v * math.pi * 5) * math.exp(-v * 4.5) * 0.12;
      // Poof: 0 -> 1
      poof = v;
      notifyListeners();
    });
  }

  void triggerDrop() {
    animCtrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    animCtrl.dispose();
    super.dispose();
  }
}

class _DustbinPainter extends CustomPainter {
  final double wobble;
  final double poof;
  _DustbinPainter({required this.wobble, required this.poof});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height);
    canvas.rotate(wobble);
    canvas.translate(-size.width / 2, -size.height);

    final w = size.width;
    final h = size.height;
    final topY = h * 0.15;
    final bottomY = h * 0.95;
    final topW = w * 0.85;
    final bottomW = w * 0.6;
    final rimRect = Rect.fromCenter(center: Offset(w / 2, topY), width: topW, height: 16);

    // 1. Draw Bin Exterior Body
    final bodyPath = Path()
      ..moveTo((w - topW) / 2, topY)
      ..lineTo((w + topW) / 2, topY)
      ..lineTo((w + bottomW) / 2, bottomY)
      ..lineTo((w - bottomW) / 2, bottomY)
      ..close();
      
    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFFFDF4E5));

    // 2. Stroke outline for body
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    canvas.drawLine(Offset((w - topW) / 2, topY), Offset((w - bottomW) / 2, bottomY), strokePaint);
    canvas.drawLine(Offset((w + topW) / 2, topY), Offset((w + bottomW) / 2, bottomY), strokePaint);
    canvas.drawLine(Offset((w - bottomW) / 2, bottomY), Offset((w + bottomW) / 2, bottomY), strokePaint);

    // 3. Draw Dark Interior Hole (the top ellipse)
    final gradient = RadialGradient(
      center: const Alignment(0, 0),
      radius: 1.0,
      colors: [Colors.black87, Colors.black],
    ).createShader(rimRect);
    canvas.drawOval(rimRect, Paint()..shader = gradient);

    // 4. Draw rim outline
    canvas.drawOval(rimRect, strokePaint);

    // 5. Small vertical hand-drawn details
    final detailPaint = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w / 2 - 12, topY + 16), Offset(w / 2 - 10, topY + 45), detailPaint);
    canvas.drawLine(Offset(w / 2 + 12, topY + 16), Offset(w / 2 + 10, topY + 45), detailPaint);
    canvas.drawLine(Offset(w / 2, topY + 18), Offset(w / 2, topY + 50), detailPaint);

    if (poof > 0 && poof < 1.0) {
      _drawPoof(canvas, Offset(w / 2, topY));
    }

    canvas.restore();
  }

  void _drawPoof(Canvas canvas, Offset center) {
    final t = poof;
    final paint = Paint()..color = Colors.black87..style = PaintingStyle.fill;
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * math.pi + math.pi + 0.1; 
      final dist = 5.0 + math.sin(t * math.pi) * 45.0 * (0.6 + 0.6 * (i % 3));
      final dx = math.cos(angle) * dist;
      final dy = math.sin(angle) * dist + (t * t * 60.0);
      final pos = center + Offset(dx, dy);
      final size = 4.0 + (i % 3);
      
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(t * 10.0 + i);
      
      if (i.isEven) {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: size, height: size * 1.2), paint);
      } else {
        final path = Path()..moveTo(0, -size)..lineTo(size, size)..lineTo(-size, size)..close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DustbinPainter old) => old.wobble != wobble || old.poof != poof;
}

class _DustbinWidget extends StatelessWidget {
  final _DustbinController controller;
  const _DustbinWidget({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CustomPaint(
        size: const Size(80, 100),
        painter: _DustbinPainter(wobble: controller.wobble, poof: controller.poof),
      ),
    );
  }
}

class DiscoverFeedScreen extends StatefulWidget {
  const DiscoverFeedScreen({super.key});
  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _profiles = [];
  int _currentIndex = 0;
  int _page = 1;
  bool _isLoading = true;
  bool _hasMore = true;
  bool _isFetchingNextBatch = false;
  int _cardPhotoIndex = 0;

  // Threshold logic: when the user reaches this many cards from the end of the queue,
  // we proactively fetch the next batch so it's ready by the time they finish the current cards.
  static const int PREFETCH_THRESHOLD = 3;

  final _netController = _NetBasketController();
  late final _DustbinController _dustbinController;
  final GlobalKey _dustbinKey = GlobalKey();

  late AnimationController _detailsCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _cardScaleAnim;
  bool get _detailsVisible => _detailsCtrl.value > 0.0;

  void _openDetails() => _detailsCtrl.animateTo(1.0, duration: const Duration(milliseconds: 480), curve: Curves.easeOutCubic);
  void _closeDetails() => _detailsCtrl.animateTo(0.0, duration: const Duration(milliseconds: 320), curve: Curves.easeInCubic);

  @override
  void initState() {
    super.initState();
    _dustbinController = _DustbinController()..init(this);
    _detailsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _detailsCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 0.5).animate(CurvedAnimation(parent: _detailsCtrl, curve: Curves.easeOut));
    _cardScaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _detailsCtrl, curve: Curves.easeOutCubic));
    _fetchFeed(reset: true);
  }

  @override
  void dispose() {
    _dustbinController.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  void _precacheImages(List<Map<String, dynamic>> batch) {
    if (!mounted) return;
    for (final profile in batch) {
      final pictures = profile['pictures'] as List?;
      if (pictures != null && pictures.isNotEmpty) {
        for (final pic in pictures) {
          final url = pic['url'] as String?;
          if (url != null && url.isNotEmpty) {
            precacheImage(CachedNetworkImageProvider(url), context).catchError((_) {});
          }
        }
      }
    }
  }

  Future<void> _fetchFeed({bool reset = false}) async {
    if (!_hasMore && !reset) return;
    
    // Prevent overlapping fetch calls if user swipes fast past the threshold
    if (!reset && _isFetchingNextBatch) return;

    if (reset) {
      setState(() => _isLoading = true);
      _page = 1; 
      _hasMore = true; 
    } else {
      _isFetchingNextBatch = true;
    }
    
    try {
      // Fetch batch of 10 profiles
      final profiles = await DiscoverService.getFeed(page: _page, limit: 10);
      
      if (mounted) {
        _precacheImages(profiles);
        setState(() {
          if (reset) { 
            _profiles = profiles; 
            _currentIndex = 0; 
          }
          else { 
            _profiles.addAll(profiles); 
          }
          
          if (profiles.isEmpty) {
            _hasMore = false;
          }
          _page++;
        });
      }
    } catch (e) {
      debugPrint('Fetch feed error: $e');
      // Subtle failure handling: _hasMore remains true, user can try swiping again
      // to re-trigger the fetch, and it doesn't block already-loaded cards.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingNextBatch = false;
        });
      }
    }
  }

  Map<String, dynamic>? get _currentProfile =>
      (_profiles.isNotEmpty && _currentIndex < _profiles.length) ? _profiles[_currentIndex] : null;

  Future<void> _onAction(String action) async {
    final profile = _currentProfile;
    if (profile == null) return;
    final id = profile['_id'] as String? ?? '';
    
    // Optimistically update the UI so the next card shows instantly
    if (_detailsVisible) {
      _detailsCtrl.animateTo(0.0, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
    }
    setState(() { _cardPhotoIndex = 0; _currentIndex++; });
    
    // Fetch more profiles in the background if we're running low
    // Trigger fetch if the number of remaining cards is less than or equal to PREFETCH_THRESHOLD
    if ((_profiles.length - _currentIndex) <= PREFETCH_THRESHOLD && _hasMore && !_isFetchingNextBatch) {
      _fetchFeed();
    }

    // Process network request asynchronously
    if (!id.startsWith('mock')) {
      Map<String, dynamic>? res;
      try {
        if (action == 'like') res = await DiscoverService.likeProfile(id);
        else if (action == 'pass') DiscoverService.passProfile(id);
        else if (action == 'superlike') res = await DiscoverService.superlikeProfile(id);
        
        if (res != null && (res['matchFormed'] == true || res['conversationId'] != null) && mounted) {
          final convId = res['conversationId'] as String?;
          if (convId != null) _showMatchDialog(profile, convId);
        }
      } catch (e) {
        debugPrint('Action error: $e');
        if (e.toString().contains('QUOTA_EXCEEDED') && mounted) {
          // Revert the swipe since it failed due to quota
          setState(() {
            _currentIndex = (_currentIndex - 1).clamp(0, _profiles.length);
          });
          _showPaywallDialog(action == 'superlike' ? 'Out of Superlikes!' : 'Out of Likes!');
        }
      }
    }
  }

  void _showMatchDialog(Map<String, dynamic> partner, String conversationId) {
    final name = partner['name'] ?? 'Match';
    final photoUrl = _getPhoto(partner);
    showDialog(
      context: context, barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("IT'S A MATCH! 🎉", style: TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w900, color: _burgundy, letterSpacing: 2)),
            const SizedBox(height: 16),
            Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _burgundy, width: 2.5)),
              child: ClipOval(child: photoUrl.isNotEmpty ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover) : Container(color: Colors.grey[200]))),
            const SizedBox(height: 16),
            Text('You and $name liked each other!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
            const SizedBox(height: 6),
            Text('Start a conversation now.', style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.5))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => IndividualChatScreen(conversationId: conversationId, partner: partner)));
                },
                style: ElevatedButton.styleFrom(backgroundColor: _burgundy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)), elevation: 0),
                child: const Text('SEND A MESSAGE', style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Keep Swiping', style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w900, color: _burgundy, letterSpacing: 2)),
            const SizedBox(height: 16),
            const Text('You have run out of free actions.\nUpgrade to Premium for unlimited likes!', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                },
                style: ElevatedButton.styleFrom(backgroundColor: _burgundy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)), elevation: 0),
                child: const Text('GET PREMIUM', style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Maybe Later', style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
        ),
      ),
    );
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
    final id = profile['_id']?.toString() ?? '0';
    const fallbacks = [
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

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _burgundy,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 48,
        backgroundColor: _bgCream, elevation: 0, surfaceTintColor: Colors.transparent,
        title: const Text(
          'DISCOVER',
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading && _profiles.isEmpty
            ? Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              )
            : _currentProfile == null ? _buildEmptyState() : AnimatedBuilder(
                    animation: _detailsCtrl,
                    builder: (context, _) {
                      return Stack(children: [
                        Transform.scale(scale: _cardScaleAnim.value, alignment: Alignment.topCenter, child: _buildCardStack()),
                        if (_detailsVisible) Positioned.fill(child: GestureDetector(onTap: _closeDetails, child: Container(color: Colors.black.withOpacity(_fadeAnim.value)))),
                        if (_detailsVisible && _currentProfile != null) SlideTransition(position: _slideAnim, child: _buildFullDetailsSheet()),
                      ]);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.12)), child: const Icon(Icons.auto_awesome, color: _bgCream, size: 36)),
          const SizedBox(height: 20),
          const Text('No More Profiles', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _bgCream)),
          const SizedBox(height: 8),
          const Text("You've seen all verified students in your area.\nChange filters or check back later!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _fetchFeed(reset: true), icon: const Icon(Icons.refresh_rounded), label: const Text('REFRESH FEED'),
            style: ElevatedButton.styleFrom(backgroundColor: _bgCream, foregroundColor: _burgundy, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)), textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 11)),
          ),
        ]),
      ),
    );
  }

  Widget _buildCardStack() {
    final bottomPad = MediaQuery.of(context).padding.bottom + 16;
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        width: constraints.maxWidth, height: constraints.maxHeight,
        child: Stack(
          children: [
            Positioned(
              top: 0, left: 0, right: 0,
              child: _NetBasketWidget(controller: _netController),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 0, left: 0, right: 0,
              child: Center(child: _DustbinWidget(key: _dustbinKey, controller: _dustbinController)),
            ),
            Positioned.fill(
              child: Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                child: _PhysicsSwipeCard(
                  key: ValueKey('${_currentProfile!['_id']}_$_currentIndex'),
                  profile: _currentProfile!, currentPhotoIndex: _cardPhotoIndex, photoCount: _getPhotoCount(_currentProfile),
                  getPhoto: (idx) => _getPhoto(_currentProfile, photoIndex: idx), formatHeight: _formatHeight,
                  onPhotoChange: (idx) => setState(() => _cardPhotoIndex = idx), onAction: _onAction, onShowDetails: _openDetails, 
                  netController: _netController, dustbinController: _dustbinController, dustbinKey: _dustbinKey,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFullDetailsSheet() {
    return FullProfileSheet(profile: _currentProfile!, onClose: _closeDetails, onLike: () => _onAction('like'), onPass: () => _onAction('pass'));
  }
}

class _PhysicsSwipeCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final int currentPhotoIndex;
  final int photoCount;
  final String Function(int) getPhoto;
  final String Function(dynamic) formatHeight;
  final void Function(int) onPhotoChange;
  final void Function(String) onAction;
  final VoidCallback onShowDetails;
  final _NetBasketController netController;
  final _DustbinController dustbinController;
  final GlobalKey dustbinKey;

  const _PhysicsSwipeCard({
    Key? key,
    required this.profile, required this.currentPhotoIndex, required this.photoCount,
    required this.getPhoto, required this.formatHeight, required this.onPhotoChange,
    required this.onAction, required this.onShowDetails, required this.netController, 
    required this.dustbinController, required this.dustbinKey,
  }) : super(key: key);

  @override
  State<_PhysicsSwipeCard> createState() => _PhysicsSwipeCardState();
}

enum _AnimMode { idle, snapBack, toss, drop }

class _PhysicsSwipeCardState extends State<_PhysicsSwipeCard> with TickerProviderStateMixin {
  Offset _drag = Offset.zero;
  _AnimMode _mode = _AnimMode.idle;

  late AnimationController _ctrl;
  Offset _arcP0 = Offset.zero;
  Offset _arcP1 = Offset.zero;
  Offset _arcP2 = Offset.zero;
  double _releaseVx = 0.0;
  Offset _dropOrigin = Offset.zero;
  Offset _snapStart = Offset.zero;

  String? _pendingAction;
  Size _cardSize = const Size(400, 680);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this)..addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // _onTick removed to optimize animation performance

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    switch (_mode) {
      case _AnimMode.snapBack:
        setState(() { _mode = _AnimMode.idle; _drag = Offset.zero; });
        break;
      case _AnimMode.toss:
        final action = _pendingAction ?? 'like';
        widget.netController.triggerCatch(isSuperlike: action == 'superlike');
        HapticFeedback.mediumImpact();
        if (action == 'superlike') {
          Future.delayed(const Duration(milliseconds: 90), () => HapticFeedback.heavyImpact());
        }
        Future.delayed(const Duration(milliseconds: 40), () {
          if (mounted) widget.onAction(action);
        });
        break;
      case _AnimMode.drop:
        if (mounted) widget.onAction('pass');
        break;
      case _AnimMode.idle:
        break;
    }
  }

  Offset _quadBezier(Offset p0, Offset p1, Offset p2, double t) {
    final mt = 1.0 - t;
    return Offset(mt * mt * p0.dx + 2 * mt * t * p1.dx + t * t * p2.dx, mt * mt * p0.dy + 2 * mt * t * p1.dy + t * t * p2.dy);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_mode != _AnimMode.idle) return;
    setState(() => _drag += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_mode != _AnimMode.idle) return;
    final vel = d.velocity.pixelsPerSecond;
    if (_drag.dy < -85 || vel.dy < -650) { _launchToss('like', vel.dx); return; }
    if (_drag.dy > 85 || vel.dy > 650) { _launchDrop(vel.dx); return; }
    _snapBack();
  }

  void _launchToss(String action, double velocityX) {
    if (_mode != _AnimMode.idle) return;
    HapticFeedback.lightImpact();
    _pendingAction = action;
    _mode = _AnimMode.toss;
    _releaseVx = velocityX;
    _arcP0 = _drag;
    final targetDy = -(_cardSize.height * 0.5) + 26.0;
    _arcP2 = Offset(0, targetDy);
    _arcP1 = Offset(_arcP0.dx + velocityX * 0.04, _arcP0.dy - (_cardSize.height * 0.40));
    _ctrl.duration = action == 'superlike' ? const Duration(milliseconds: 650) : const Duration(milliseconds: 350);
    _ctrl.forward(from: 0.0);
  }

  void _launchDrop(double velocityX) {
    if (_mode != _AnimMode.idle) return;
    HapticFeedback.lightImpact();
    _pendingAction = 'pass';
    _mode = _AnimMode.drop;
    _releaseVx = velocityX;
    _arcP0 = _drag;

    double targetDy = (_cardSize.height * 0.5) + 125.0;
    double targetDx = 0.0;

    // Dynamic coordinate calculation to target the bin mouth
    final RenderBox? dustbinBox = widget.dustbinKey.currentContext?.findRenderObject() as RenderBox?;
    if (dustbinBox != null) {
      final RenderBox cardBox = context.findRenderObject() as RenderBox;
      final dustbinGlobal = dustbinBox.localToGlobal(dustbinBox.size.center(Offset.zero));
      final cardCenterGlobal = cardBox.localToGlobal(cardBox.size.center(Offset.zero));
      final offsetToDustbin = dustbinGlobal - cardCenterGlobal;
      targetDx = offsetToDustbin.dx;
      // Drop deeply enough so the top edge vanishes behind the rim
      targetDy = offsetToDustbin.dy + 45.0; 
    }

    _arcP2 = Offset(targetDx, targetDy);
    _arcP1 = Offset(_arcP0.dx + velocityX * 0.04, _arcP0.dy + (_cardSize.height * 0.30));
    _ctrl.duration = const Duration(milliseconds: 480);
    
    // Delay wobble and poof to sync with visual entry
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        widget.dustbinController.triggerDrop();
        HapticFeedback.mediumImpact();
      }
    });

    _ctrl.forward(from: 0.0);
  }

  void _snapBack() {
    _snapStart = _drag;
    _mode = _AnimMode.snapBack;
    _ctrl.duration = const Duration(milliseconds: 250);
    _ctrl.forward(from: 0.0);
  }

  void _triggerAction(String action) {
    if (_mode != _AnimMode.idle) return;
    if (action == 'pass') _launchDrop(0.0);
    else _launchToss(action, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final photoUrl = widget.getPhoto(widget.currentPhotoIndex);

    return LayoutBuilder(builder: (ctx, constraints) {
      _cardSize = constraints.biggest;
      
      final Widget cachedCardContent = ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(fit: StackFit.expand, children: [
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          Positioned(
            top: 0, left: 0, right: 0, bottom: 120,
            child: photoUrl.isNotEmpty ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover, placeholder: (_, __) => const ColoredBox(color: Colors.black12), errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1A1A), child: Icon(Icons.person, size: 80, color: Colors.white30))) : const ColoredBox(color: Color(0xFF1A1A1A)),
          ),
          Positioned(
            bottom: 120, left: 0, right: 0, height: 180,
            child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black]))),
          ),
          
          if (widget.photoCount > 1) Positioned(top: 14, left: 14, right: 14, child: Row(children: List.generate(widget.photoCount, (i) { 
            final isActive = i == widget.currentPhotoIndex;
            return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 2.5), height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: isActive ? Colors.white : Colors.white.withOpacity(0.35), boxShadow: isActive ? [BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 6)] : null))); 
          }))),
          
          Positioned(top: 0, left: 0, right: 0, bottom: _cardSize.height * 0.45, child: Row(children: [Expanded(flex: 4, child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () { if (widget.currentPhotoIndex > 0) widget.onPhotoChange(widget.currentPhotoIndex - 1); })), const Spacer(flex: 2), Expanded(flex: 4, child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () { if (widget.currentPhotoIndex < widget.photoCount - 1) widget.onPhotoChange(widget.currentPhotoIndex + 1); }))])),
          
          Positioned(bottom: 118, left: 20, right: 20, child: GestureDetector(onTap: widget.onShowDetails, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text('${profile['name'] ?? ''}, ${profile['age'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -0.5, shadows: [Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0,2))]))), 
              if (profile['identityStatus'] == 'verified') ...[
                const SizedBox(width: 8), 
                Container(width: 20, height: 20, decoration: BoxDecoration(color: const Color(0xFF8B1538), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF8B1538).withOpacity(0.65), blurRadius: 10, spreadRadius: 2)]), child: const Center(child: Icon(Icons.check_rounded, color: Colors.white, size: 13)))
              ]
            ]), 
            if (profile['school'] != null || profile['course'] != null) ...[
              const SizedBox(height: 6), 
              Row(children: [const Icon(Icons.school_outlined, color: Color(0xFFC98AA0), size: 14), const SizedBox(width: 6), Expanded(child: Text('${profile['school'] ?? ''} ${profile['course'] != null ? '(${profile['course']})' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 13)))])
            ], 
            if (profile['bio'] != null && (profile['bio'] as String).isNotEmpty) ...[
              const SizedBox(height: 6), 
              Text('"${profile['bio']}"', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 13, height: 1.4, fontStyle: FontStyle.italic))
            ], 
            const SizedBox(height: 12), 
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (profile['height'] != null) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.35), width: 0.5)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.straighten_rounded, color: Colors.white, size: 11), const SizedBox(width: 4), Text(widget.formatHeight(profile['height']), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))])), 
              if (profile['lookingFor'] != null) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF8B1538), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFC98AA0), width: 0.5)), child: Text((profile['lookingFor'] as String).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)))
            ]),
          ]))),
          
          Positioned(bottom: 84, left: 0, right: 0, child: Center(child: _AnimatedSwipeHint())),
          
          Positioned(bottom: 18, left: 0, right: 0, child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  _actionBtn(icon: Icons.close_rounded, bgColor: const Color(0xFF333333), fgColor: Colors.white, size: 44, iconSize: 22, onTap: () => _triggerAction('pass')), 
                  const SizedBox(width: 12), 
                  _actionBtn(icon: Icons.star_rounded, bgColor: const Color(0xFFFFC107), fgColor: Colors.black, size: 36, iconSize: 18, onTap: () => _triggerAction('superlike')), 
                  const SizedBox(width: 12), 
                  _actionBtn(icon: Icons.favorite_rounded, bgColor: const Color(0xFFD32F2F), fgColor: Colors.white, size: 44, iconSize: 20, onTap: () => _triggerAction('like'))
                ]
              ),
            ),
          )),
        ]),
      );

      return AnimatedBuilder(
        animation: _ctrl,
        child: cachedCardContent,
        builder: (context, child) {
          double tiltX = 0.0;
          double tiltY = 0.0;
          double tiltZ = 0.0;
          double elevation = 0.0;
          double scaleX = 1.0;
          double scaleY = 1.0;
          double opacity = 1.0;
          Offset currentDrag = _drag;
          
          final v = _ctrl.value;

          if (_mode == _AnimMode.idle) {
            tiltX = (currentDrag.dy * -0.0006).clamp(-0.3, 0.3);
            tiltY = (currentDrag.dx * 0.0006).clamp(-0.3, 0.3);
            tiltZ = currentDrag.dx * 0.0002;
            elevation = (currentDrag.distance / 200).clamp(0.0, 1.0);
          } else if (_mode == _AnimMode.snapBack) {
            final t = Curves.easeOutCubic.transform(v);
            currentDrag = Offset.lerp(_snapStart, Offset.zero, t)!;
            tiltX = (currentDrag.dy * -0.0006).clamp(-0.3, 0.3);
            tiltY = (currentDrag.dx * 0.0006).clamp(-0.3, 0.3);
            tiltZ = currentDrag.dx * 0.0002;
            elevation = (currentDrag.distance / 200).clamp(0.0, 1.0);
          } else if (_mode == _AnimMode.toss) {
            final t = Curves.easeOutQuart.transform(v);
            currentDrag = _quadBezier(_arcP0, _arcP1, _arcP2, t);
            
            double scale = 1.0;
            if (v < 0.2) {
              scale = 1.0 + (v / 0.2) * 0.05; 
            } else {
              final shrink = Curves.easeIn.transform((v - 0.2) / 0.8);
              scale = 1.05 - (shrink * 1.05); 
            }
            scaleX = scaleY = scale;
            
            opacity = (1.0 - (v > 0.95 ? (v - 0.95) / 0.05 : 0.0)).clamp(0.0, 1.0);
            
            tiltX = (_releaseVx != 0 ? _drag.dy * -0.0006 : 0.0) + (v * 1.5); 
            tiltY = (currentDrag.dx * 0.0006) + (v * _releaseVx * 0.0005);
            tiltZ = (currentDrag.dx * 0.0002) + (v * _releaseVx * 0.0002);
            elevation = (v < 0.5) ? (v * 2.0) : (1.0 - (v - 0.5) * 2.0);
          } else if (_mode == _AnimMode.drop) {
            final eased = Curves.easeIn.transform(v); // accelerating descent
            currentDrag = _quadBezier(_arcP0, _arcP1, _arcP2, eased);
            
            // Anisotropic scale: shrinks horizontally faster as it enters slot
            if (v > 0.4) {
              final shrinkV = (v - 0.4) / 0.6;
              final shrink = Curves.easeIn.transform(shrinkV);
              scaleX = 1.0 - (shrink * 0.95);
              scaleY = 1.0 - (shrink * 0.95);
            }
            
            opacity = (1.0 - (v > 0.65 ? (v - 0.65) / 0.35 : 0.0)).clamp(0.0, 1.0);
            
            tiltX = (_drag.dy * -0.0006) - (v * 2.2); // Aggressive tumbling forward
            tiltY = (currentDrag.dx * 0.0006);
            tiltZ = (currentDrag.dx * 0.0002) + (v * (_releaseVx > 0 ? 1.0 : -1.0) * 0.8);
            elevation = (1.0 - v).clamp(0.0, 1.0);
          }

          final Matrix4 transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(tiltX)
            ..rotateY(tiltY)
            ..rotateZ(tiltZ)
            ..scale(scaleX, scaleY, 1.0);

          final shadowColor = Colors.black.withOpacity((0.15 + (elevation * 0.15)).clamp(0.0, 1.0));
          final blur = 15.0 + (elevation * 45.0);
          final spread = 2.0 + (elevation * 12.0);
          final offsetY = 10.0 + (elevation * 35.0);

          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: currentDrag,
              child: Transform(
                alignment: Alignment.center,
                transform: transform,
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(color: shadowColor, offset: Offset(0, offsetY), blurRadius: blur, spreadRadius: spread),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _actionBtn({required IconData icon, required Color bgColor, required Color fgColor, required double size, required double iconSize, required VoidCallback onTap}) {
    return _BouncingButton(
      onTap: onTap,
      child: Container(
        width: size, height: size, 
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), 
        child: Icon(icon, color: fgColor, size: iconSize)
      ),
    );
  }
}

class _AnimatedSwipeHint extends StatefulWidget {
  @override State<_AnimatedSwipeHint> createState() => _AnimatedSwipeHintState();
}
class _AnimatedSwipeHintState extends State<_AnimatedSwipeHint> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) => Transform.translate(offset: Offset(0, Curves.easeInOut.transform(_ctrl.value) * -3.0), child: child),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.35), width: 0.5)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 14), SizedBox(width: 3), Text('swipe up to like', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500))])),
    );
  }
}

class _BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _BouncingButton({required this.child, required this.onTap});
  @override State<_BouncingButton> createState() => _BouncingButtonState();
}
class _BouncingButtonState extends State<_BouncingButton> {
  bool _pressed = false;
  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(scale: _pressed ? 0.92 : 1.0, duration: const Duration(milliseconds: 100), curve: Curves.easeOut, child: widget.child),
    );
  }
}

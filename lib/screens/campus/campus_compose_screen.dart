import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/top_notification.dart';

class CampusComposeScreen extends StatefulWidget {
  final Color burgundy;
  final Function(String text, bool isAnonymous) onSubmit;

  const CampusComposeScreen({super.key, required this.burgundy, required this.onSubmit});

  @override
  State<CampusComposeScreen> createState() => _CampusComposeScreenState();
}

class _CampusComposeScreenState extends State<CampusComposeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isAnonymous = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() => _isSubmitting = true);
    await widget.onSubmit(text, _isAnonymous);
    if (mounted) {
       setState(() => _isSubmitting = false);
    }
  }

  void _showNotification(String message, Color color) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TopNotification(
        message: message,
        backgroundColor: color,
        onDismissed: () {
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFB),
      appBar: AppBar(
        backgroundColor: AppColors.textColor1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'New Whisper', 
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final count = _controller.text.length;
                  return Text(
                    '$count / 280',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: count >= 280
                          ? Colors.orangeAccent
                          : Colors.white70,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background layer
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/redTreebg.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Text input ─────────────────────────────────────────
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F4F2).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        expands: true,
                        maxLength: 280,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        textInputAction: TextInputAction.newline,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          height: 1.5,
                          color: const Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          hintText: _isAnonymous
                              ? "Drop a whisper… 🤫"
                              : "What's on your mind? ✨",
                          border: InputBorder.none,
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 18,
                            color: Colors.black26,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Footer row: char count + Post button ───────────────
                  Row(
                    children: [
                      const Spacer(),
                      // Animated toggle pill
                      GestureDetector(
                        onTap: () {
                          setState(() => _isAnonymous = !_isAnonymous);
                          _showNotification(
                            _isAnonymous ? 'Posting Anonymously' : 'Posting Publicly',
                            Colors.black87
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isAnonymous
                                ? widget.burgundy
                                : Colors.green.shade600,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: (_isAnonymous
                                        ? widget.burgundy
                                        : Colors.green.shade600)
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  _isAnonymous
                                      ? Icons.person_off_rounded
                                      : Icons.person_rounded,
                                  key: ValueKey(_isAnonymous),
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  _isAnonymous ? 'Anon' : 'Public',
                                  key: ValueKey(_isAnonymous),
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isSubmitting)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: widget.burgundy,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () {
                             FocusScope.of(context).unfocus();
                             _submit();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.burgundy,
                                  Color.lerp(widget.burgundy,
                                          Colors.deepOrange, 0.25)!,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      widget.burgundy.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Post',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

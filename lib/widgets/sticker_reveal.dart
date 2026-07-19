import 'package:flutter/material.dart';

class StickerReveal extends StatefulWidget {
  final Widget child;

  const StickerReveal({
    super.key,
    required this.child,
  });

  @override
  State<StickerReveal> createState() => _StickerRevealState();
}

class _StickerRevealState extends State<StickerReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Trigger entrance animation immediately
    _controller.forward();
  }

  @override
  void didUpdateWidget(StickerReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the widget's identity changes (e.g., new key), replay animation
    // Or we could replay it if a specific "shouldReplay" flag was passed.
    // For now, attaching a new ValueKey to StickerReveal will recreate its state
    // and replay the animation automatically.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

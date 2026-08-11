import 'package:flutter/material.dart';

class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool isForward;

  SharedAxisPageRoute({required this.page, this.isForward = true})
      : super(
          opaque: false, // Let the outgoing page show through
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // The OUTGOING page fades out during the first 50% of the animation
            // driven by secondaryAnimation (which goes 0→1 as this new page comes in).
            final exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
              ),
            );

            // The INCOMING page starts invisible and fades in during the last 50%.
            final enterFade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
              ),
            );

            // Slide the incoming page from the side
            final slideIn = Tween<Offset>(
              begin: Offset(isForward ? 0.15 : -0.15, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            );

            return Stack(
              children: [
                // Outgoing page fades out underneath
                FadeTransition(
                  opacity: exitFade,
                  child: const SizedBox.expand(),
                ),
                // Incoming page slides in and fades in on top
                FadeTransition(
                  opacity: enterFade,
                  child: SlideTransition(
                    position: slideIn,
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
}

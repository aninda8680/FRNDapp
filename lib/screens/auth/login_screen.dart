import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isCodeSent = false;

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Get Verified')),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 135,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: isKeyboardVisible ? 6.0 : 0.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, blurValue, child) {
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: blurValue.clamp(0.001, 10.0),
                      sigmaY: blurValue.clamp(0.001, 10.0),
                    ),
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/images/login.png',
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 5),
                        Text(
                          _isCodeSent ? 'ENTER CODE' : 'ENTER COLLEGE ID',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        SketchyContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            keyboardType: _isCodeSent ? TextInputType.number : TextInputType.emailAddress,
                            textAlign: _isCodeSent ? TextAlign.center : TextAlign.start,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: _isCodeSent ? '- - - - - -' : 'student@college.edu',
                            ),
                            style: _isCodeSent 
                                ? Theme.of(context).textTheme.displaySmall 
                                : Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const Spacer(),
                        SketchyButton(
                          text: _isCodeSent ? 'VERIFY & ENTER' : 'SEND MAGIC LINK',
                          onPressed: () {
                            if (_isCodeSent) {
                              Navigator.pushNamed(context, '/setup');
                            } else {
                              setState(() {
                                _isCodeSent = true;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

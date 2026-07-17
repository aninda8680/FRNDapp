import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'routes.dart';

void main() {
  runApp(const FrndApp());
}

class FrndApp extends StatelessWidget {
  const FrndApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FRND MVP',
      theme: AppTheme.theme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}

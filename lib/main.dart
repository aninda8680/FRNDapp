import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'routes.dart';
import 'config/dev_config.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FrndApp());
}

class FrndApp extends StatelessWidget {
  const FrndApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FRND MVP',
      theme: AppTheme.theme,
      initialRoute: DevConfig.initialRouteOverride ?? AppRoutes.splash,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}

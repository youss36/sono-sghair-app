import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SonoApp());
}

class SonoApp extends StatelessWidget {
  const SonoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SONO SGHAIER',
      theme: AppTheme.dark(),
      home: const LoginScreen(),
    );
  }
}

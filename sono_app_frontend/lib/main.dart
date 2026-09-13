import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  // حماية من الشاشة الحمراء: أي خطأ في البناء يعرض رسالة لطيفة بدل التعطل.
  ErrorWidget.builder = (details) => Material(
        color: AppColors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Une erreur inattendue est survenue. Redémarrez l\u2019application.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ),
      );
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

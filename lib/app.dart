import 'package:flutter/material.dart';
import 'package:kulkharcha/features/onboarding/screens/splash_screen.dart';
import 'core/theme/app_theme.dart';

class KulKharchaApp extends StatelessWidget {
  const KulKharchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KulKharcha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Entry point Splash Screen hoga
      home: const SplashScreen(),
    );
  }
}

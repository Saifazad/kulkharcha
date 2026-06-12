import 'package:flutter/material.dart';
import 'package:kulkharcha/features/onboarding/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

class KulKharchaApp extends StatefulWidget {
  const KulKharchaApp({super.key});

  @override
  State<KulKharchaApp> createState() => _KulKharchaAppState();
}

class _KulKharchaAppState extends State<KulKharchaApp> {
  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeStr = prefs.getString('theme_mode') ?? 'system';
      if (themeStr == 'dark') {
        themeNotifier.value = ThemeMode.dark;
      } else if (themeStr == 'light') {
        themeNotifier.value = ThemeMode.light;
      } else {
        themeNotifier.value = ThemeMode.system;
      }
    } catch (e) {
      debugPrint("Error loading theme preference: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          title: 'KulKharcha',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

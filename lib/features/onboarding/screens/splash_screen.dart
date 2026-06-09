import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kulkharcha/features/onboarding/onboarding_screen.dart';
import 'package:kulkharcha/features/onboarding/setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Local storage ke liye
import 'package:kulkharcha/features/home/screens/home_screen.dart';
import '../../../core/constants/color_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Smooth Fade Animation Setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // 2. Decision Logic: Check if user is new or returning
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Splash ko kam se kam 2.5 - 3 seconds dikhana hai
    await Future.delayed(const Duration(milliseconds: 3000));

    // Local storage se onboarding/setup status check karna
    final prefs = await SharedPreferences.getInstance();
    final bool isOnboardingDone = prefs.getBool('onboarding_done') ?? false;
    final bool isSetupDone = (prefs.getString('user_name') ?? '').isNotEmpty;

    //  Hamesha check karein ki widget 'mounted' hai ya nahi navigation se pehle
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (!isOnboardingDone) return const OnboardingScreen();
          if (!isSetupDone) return const SetupScreen();
          return const HomeScreen();
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryEmerald,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with soft glow
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // App Branding
              const Text(
                "KUL KHARCHA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "AI-Powered Privacy-First Tracking",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

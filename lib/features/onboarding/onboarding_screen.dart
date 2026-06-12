import 'package:flutter/material.dart';
import 'package:kulkharcha/features/onboarding/onboarding_model.dart';
import 'package:kulkharcha/features/onboarding/screens/permission_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/color_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool isLastPage = false;
  bool _isCompletingOnboarding = false;

  // Senior Dev Logic: Ek baar onboarding dekh li to dubara nahi dikhegi
  Future<void> _completeOnboarding() async {
    if (_isCompletingOnboarding) return;
    _isCompletingOnboarding = true;

    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true); // Privacy-safe local storage

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PermissionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Swipeable Content
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingContents.length,
            onPageChanged: (index) {
              final lastPageReached = index == onboardingContents.length - 1;
              setState(() => isLastPage = lastPageReached);
              // if (lastPageReached) {
              //   _completeOnboarding();
              // }
            },
            itemBuilder: (context, index) {
              final data = onboardingContents[index];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with soft emerald glow
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.05)
                          : AppColors.primaryEmerald.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.icon,
                      size: 100,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 45),
                    child: Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Bottom Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip Button
                TextButton(
                  onPressed: () =>
                      _pageController.jumpToPage(onboardingContents.length - 1),
                  child: Text(
                    "SKIP",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Smooth Dots Indicator
                SmoothPageIndicator(
                  controller: _pageController,
                  count: onboardingContents.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: Theme.of(context).colorScheme.primary,
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 4,
                    spacing: 6,
                  ),
                ),

                // Next or Finish Button
                isLastPage
                    ? ElevatedButton(
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          minimumSize: const Size(100, 48), // Add minimum size
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          "FINISH",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInQuad,
                        ),
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';

class OnboardingModel {
  final String title;
  final String description;
  final IconData
  icon; // String image ki jagah IconData use karenge kyunki aap icons use kar rahe hain

  OnboardingModel({
    required this.title,
    required this.description,
    required this.icon,
  });
}

// Data list ko hamesha class ke bahar rakhte hain
final List<OnboardingModel> onboardingContents = [
  OnboardingModel(
    title: "AI Smart Tracking",
    description:
        "Bhai, aap kharch karo, hum automatic bank SMS se hisaab nikal lenge.",
    icon: Icons.auto_awesome,
  ),
  OnboardingModel(
    title: "Voice Commands",
    description:
        "Bol kar kharcha add karo. 'Bhai, 500 ka petrol' - it's that simple!",
    icon: Icons.mic_none_rounded,
  ),
  OnboardingModel(
    title: "Safe & Secure",
    description:
        "Aapka data sirf aapke phone mein hai. 100% private aur offline.",
    icon: Icons.security_outlined,
  ),
];

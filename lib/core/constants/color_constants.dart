import 'package:flutter/material.dart';

class AppColors {
  // --- Primary Palette (Screenshot se matched) ---
  static const Color primaryEmerald = Color(
    0xFF1B5E20,
  ); // Darker Green for text/titles
  static const Color accentGreen = Color(0xFF2E7D32); // Main Button Green
  static const Color softGreen = Color(
    0xFFE8F5E9,
  ); // Very light green for cards

  // --- Background Colors (Soft & Premium) ---
  // Screenshot mein white nahi, halka sa off-white/greenish background hai
  static const Color lightBackground = Color(0xFFF9FBF9);
  static const Color darkBackground = Color(0xFF121212);

  // --- Surface Colors ---
  static const Color lightSurface = Colors.white;
  static const Color darkSurface = Color(0xFF1E1E1E);

  // --- Status Colors (Premium Shades) ---
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF1E88E5);

  // --- Text Colors (High Contrast) ---
  static const Color textDark = Color(0xFF1A1C1E); // Almost black for titles
  static const Color textGrey = Color(
    0xFF6C757D,
  ); // For descriptions/skip buttons
  static const Color textLight = Colors.white;

  // --- Glassmorphic & Border Accents ---
  static Color glassWhite = Colors.white.withOpacity(0.25);
  static Color borderLight = Color(0xFFE0E0E0); // For input borders
  static Color shadowColor = Colors.black.withOpacity(0.05);

  // --- Progress Indicators (Dots) ---
  static const Color dotActive = Color(0xFF2E7D32);
  static const Color dotInactive = Color(0xFFD1D1D1);
}

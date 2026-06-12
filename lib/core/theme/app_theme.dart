import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/color_constants.dart';

class AppTheme {
  // --- LIGHT THEME (As per Screenshot Design) ---
  static ThemeData get lightTheme {
    // Base light theme taaki text colors aur framework mapping default sahi ho
    final ThemeData baseLight = ThemeData.light(useMaterial3: true);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryEmerald,
      scaffoldBackgroundColor: AppColors.lightBackground,

      colorScheme: const ColorScheme.light(
        primary: AppColors.accentGreen,
        secondary: AppColors.primaryEmerald,
        surface: AppColors.lightSurface,
        onSurface: AppColors.textDark,
        error: AppColors.error,
      ),

      // Typography - High-end Plus Jakarta Sans (Fixed and Cleaned)
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseLight.textTheme)
          .copyWith(
            displayLarge: GoogleFonts.plusJakartaSans(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 30,
            ),
            titleLarge: GoogleFonts.plusJakartaSans(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            bodyMedium: GoogleFonts.plusJakartaSans(
              color: AppColors.textGrey,
              fontSize: 16,
            ),
            bodySmall: GoogleFonts.plusJakartaSans(
              color: AppColors.textGrey,
              fontSize: 14,
            ),
          ),

      // AppBar Theme - Clean & Transparent
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Button Theme - Pill/Rounded Rect Shape
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input Decoration - Profile & Form Setup
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
      ),

      // Card Theme - Soft Elevation (Fixed CardThemeData Bug ✅)
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Chip Theme - For Category Filters (Fixed BorderSide Bug ✅)
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.accentGreen,
        labelStyle: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(
          color: Colors.transparent,
        ), // Valid structure fix
      ),
    );
  }

  // --- DARK THEME (Fully Implemented) ---
  static ThemeData get darkTheme {
    final ThemeData baseDark = ThemeData.dark(useMaterial3: true);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryEmerald,
      scaffoldBackgroundColor: AppColors.darkBackground,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGreen,
        secondary: AppColors.primaryEmerald,
        surface: AppColors.darkSurface,
        onSurface: Colors.white,
        error: AppColors.error,
      ),

      // Typography - High-end Plus Jakarta Sans
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseDark.textTheme)
          .copyWith(
            displayLarge: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 30,
            ),
            titleLarge: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            bodyMedium: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 16,
            ),
            bodySmall: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

      // AppBar Theme - Clean & Transparent for Dark Mode
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF242424),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
        ),
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF242424),
        selectedColor: AppColors.accentGreen,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(
          color: Colors.transparent,
        ),
      ),
    );
  }
}

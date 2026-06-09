import 'package:flutter/material.dart';
import 'category_model.dart'; // Deep integration with your core database model

class QuickCategory {
  final String title;
  final double amount; // Calculations friendly numeric layout
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const QuickCategory({
    required this.title,
    required this.amount,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  // --- Senior Dev Adapter Rule: Database Model ko UI Model mein map karne ke liye ---
  // Iska use karke aap CategoryModel ka real data is beautiful dynamic item mein convert kar sakte ho
  factory QuickCategory.fromCoreModel({
    required CategoryModel coreCategory,
    required double calculatedAmount,
    IconData? fallbackIcon,
  }) {
    final Color primaryColor = Color(coreCategory.colorHex);

    return QuickCategory(
      title: coreCategory.name,
      amount: calculatedAmount,
      // Icon mapping logic: Agar dynamic path handle karna ho to custom wrapper de sakte hain
      icon: fallbackIcon ?? Icons.category_rounded,
      bgColor: primaryColor.withOpacity(
        0.12,
      ), // Soft glassmorphic background shade
      iconColor: primaryColor,
    );
  }
}

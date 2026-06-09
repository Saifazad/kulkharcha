import 'package:flutter/material.dart';
// Intl package agar format ke liye use karna ho to, varna simple formatting niche de di hai
import '../../../data/models/quick_category_model.dart';
import '../../../core/constants/color_constants.dart';

class QuickCategoryCard extends StatelessWidget {
  final QuickCategory category;
  final VoidCallback? onTap;

  const QuickCategoryCard({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Screen width ke hisab se responsive sizing
    final double cardWidth = MediaQuery.of(context).size.width * 0.28;

    return Material(
      color: Colors
          .transparent, // Background transparent rakha taaki card color dikhe
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: category.iconColor.withOpacity(
          0.1,
        ), // Dynamic premium splash matching icon color
        highlightColor: category.iconColor.withOpacity(0.05),
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightSurface, // Synchronized with your token
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Wrap content safely
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: category.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, color: category.iconColor, size: 22),
              ),
              const SizedBox(height: 14),
              // Title text layout
              Text(
                category.title,
                maxLines: 1,
                overflow: TextOverflow
                    .ellipsis, // Agar name lamba ho to layout break nahi hoga
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight
                      .w600, // Thoda sharp weight premium fonts ke liye
                ),
              ),
              const SizedBox(height: 4),
              // Amount (Fixed for double value type mapping ✅)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  // Dynamic local Rupee format syntax representation
                  category.amount == 0
                      ? "₹0"
                      : "₹${category.amount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight:
                        FontWeight.w800, // Ultra bold for financial tracking
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class BudgetCard extends StatelessWidget {
  final double todayExpense;
  final double monthlyExpense;
  final double dailyLimit;
  final double monthlyLimit;
  final bool showMonthly;
  final VoidCallback onToggleDaily;
  final VoidCallback onToggleMonthly;
  final VoidCallback onSettingsTap;

  const BudgetCard({
    super.key,
    required this.todayExpense,
    required this.monthlyExpense,
    required this.dailyLimit,
    required this.monthlyLimit,
    required this.showMonthly,
    required this.onToggleDaily,
    required this.onToggleMonthly,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final expense = showMonthly ? monthlyExpense : todayExpense;
    final limit = showMonthly ? monthlyLimit : dailyLimit;
    final double progress = (limit > 0) ? (expense / limit).clamp(0.0, 1.0) : 0.0;
    final int progressPercent = (progress * 100).round();
    final double remaining = (limit - expense).clamp(0.0, double.infinity);
    final bool isOverBudget = expense > limit;

    final Color barColor = isOverBudget
        ? Colors.red[600]!
        : progressPercent > 80
            ? Colors.orange[700]!
            : const Color(0xFF1B5E20);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + settings icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("💰", style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    showMonthly ? "Is Mahine ka Kharcha" : "Aaj ka Kharcha",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onSettingsTap,
                child: const Icon(Icons.tune_rounded, color: Color(0xFF1B5E20), size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Daily / Monthly toggle
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _ToggleTab(label: "Daily",   isActive: !showMonthly, onTap: onToggleDaily),
                _ToggleTab(label: "Monthly", isActive: showMonthly,  onTap: onToggleMonthly),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Amount
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "₹${expense.toStringAsFixed(0)} ",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: isOverBudget ? Colors.red[700] : Colors.black,
                  ),
                ),
                TextSpan(
                  text: "/ ₹${limit.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F1F1),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverBudget ? "⚠️ Budget exceeded!" : "$progressPercent% of limit used",
                style: TextStyle(
                  color: isOverBudget ? Colors.red[700] : Colors.grey,
                  fontSize: 13,
                  fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (!isOverBudget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "₹${remaining.toStringAsFixed(0)} bachi",
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleTab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF1B5E20) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

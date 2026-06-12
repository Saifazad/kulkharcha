import 'package:flutter/material.dart';

class BudgetSettingsSheet extends StatefulWidget {
  final double dailyLimit;
  final double monthlyLimit;
  final Future<void> Function(double daily, double monthly) onSave;

  const BudgetSettingsSheet({
    super.key,
    required this.dailyLimit,
    required this.monthlyLimit,
    required this.onSave,
  });

  /// Call this to open the bottom sheet
  static void show(
    BuildContext context, {
    required double dailyLimit,
    required double monthlyLimit,
    required Future<void> Function(double daily, double monthly) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetSettingsSheet(
        dailyLimit: dailyLimit,
        monthlyLimit: monthlyLimit,
        onSave: onSave,
      ),
    );
  }

  @override
  State<BudgetSettingsSheet> createState() => _BudgetSettingsSheetState();
}

class _BudgetSettingsSheetState extends State<BudgetSettingsSheet> {
  late double _tempDaily;
  late double _tempMonthly;

  @override
  void initState() {
    super.initState();
    _tempDaily = widget.dailyLimit;
    _tempMonthly = widget.monthlyLimit;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 50, height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Budget Settings",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const Text(
            "Apna daily aur monthly kharcha limit set karein",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 28),

          // Daily Limit
          _LimitRow(label: "Daily Limit", icon: Icons.today_outlined, amount: _tempDaily),
          Slider(
            value: _tempDaily,
            min: 100,
            max: 10000,
            divisions: 99,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            onChanged: (val) => setState(() => _tempDaily = val),
          ),
          const _SliderRange(min: "₹100", max: "₹10,000"),
          const SizedBox(height: 24),

          // Monthly Limit
          _LimitRow(label: "Monthly Limit", icon: Icons.calendar_month_outlined, amount: _tempMonthly),
          Slider(
            value: _tempMonthly,
            min: 1000,
            max: 200000,
            divisions: 199,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            onChanged: (val) => setState(() => _tempMonthly = val),
          ),
          const _SliderRange(min: "₹1,000", max: "₹2,00,000"),
          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await widget.onSave(_tempDaily, _tempMonthly);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                "Save Budget Limits",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double amount;

  const _LimitRow({required this.label, required this.icon, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : const Color(0xFF1B5E20), size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.green.withOpacity(0.15)
                : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "₹${amount.toStringAsFixed(0)}",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green[300]
                  : const Color(0xFF1B5E20),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _SliderRange extends StatelessWidget {
  final String min;
  final String max;

  const _SliderRange({required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(min, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(max, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

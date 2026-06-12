import 'package:flutter/material.dart';

class CategorySection extends StatelessWidget {
  final Map<String, double> categoryExpenses;

  const CategorySection({super.key, required this.categoryExpenses});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Quick Categories",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.more_horiz, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 125,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _CategoryItem(
                title: "Food",
                amount: categoryExpenses['Food & Groceries'] ?? 0.0,
                icon: Icons.restaurant,
                bg: const Color(0xFFFFF3E0),
                iconColor: Colors.orange,
              ),
              const SizedBox(width: 12),
              _CategoryItem(
                title: "Fuel",
                amount: categoryExpenses['Fuel & Transport'] ?? 0.0,
                icon: Icons.local_gas_station,
                bg: const Color(0xFFFCE4EC),
                iconColor: Colors.pink,
              ),
              const SizedBox(width: 12),
              _CategoryItem(
                title: "Bills",
                amount: categoryExpenses['Bills & Recharges'] ?? 0.0,
                icon: Icons.receipt_long,
                bg: const Color(0xFFE3F2FD),
                iconColor: Colors.blue,
              ),
              const SizedBox(width: 12),
              _CategoryItem(
                title: "Shopping",
                amount: categoryExpenses['Shopping'] ?? 0.0,
                icon: Icons.shopping_bag,
                bg: const Color(0xFFF3E5F5),
                iconColor: Colors.purple,
              ),
              const SizedBox(width: 12),
              _CategoryItem(
                title: "Medical",
                amount: categoryExpenses['Medical & Health'] ?? 0.0,
                icon: Icons.medical_services,
                bg: const Color(0xFFFFEBEE),
                iconColor: Colors.red,
              ),
              const SizedBox(width: 12),
              _CategoryItem(
                title: "Farming",
                amount: categoryExpenses['Kheti/Farming'] ?? 0.0,
                icon: Icons.agriculture,
                bg: const Color(0xFFE8F5E9),
                iconColor: Colors.green,
              ),
              const SizedBox(width: 12),
              _CategoryItem(
                title: "Cash",
                amount: categoryExpenses['Cash (ATM)'] ?? 0.0,
                icon: Icons.local_atm,
                bg: const Color(0xFFE0F2F1),
                iconColor: Colors.teal,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color bg;
  final Color iconColor;

  const _CategoryItem({
    required this.title,
    required this.amount,
    required this.icon,
    required this.bg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? iconColor.withOpacity(0.15)
                : bg,
            radius: 18,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            "₹${amount.toStringAsFixed(0)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

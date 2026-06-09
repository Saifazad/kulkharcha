import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeHeader extends StatelessWidget {
  final String userName;

  const HomeHeader({super.key, required this.userName});

  String get _currentDate => DateFormat('dd MMM, EEE').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("👋", style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  "Namaste, $userName",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              _currentDate,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const Icon(Icons.dark_mode_outlined, size: 28),
      ],
    );
  }
}

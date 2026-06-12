import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app.dart';

class HomeHeader extends StatelessWidget {
  final String userName;

  const HomeHeader({super.key, required this.userName});

  String get _currentDate => DateFormat('dd MMM, EEE').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        GestureDetector(
          onTap: () async {
            try {
              final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
              themeNotifier.value = newMode;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('theme_mode', newMode == ThemeMode.light ? 'light' : 'dark');
            } catch (e) {
              debugPrint("Error saving theme choice: $e");
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
              size: 28,
              color: isDark ? Colors.amber[400] : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

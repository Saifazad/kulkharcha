import 'package:flutter/material.dart';
import 'package:kulkharcha/core/widgets/custom_textfield.dart';
import 'package:kulkharcha/features/home/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _saveNameAndGo() async {
    final name = _nameController.text.trim();

    if (name.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      // Privacy-safe local storage
      await prefs.setString('user_name', name);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          // Smooth transition to Dashboard
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      // Bhai wala personal touch notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Bhai, apna naam to bata do!"),
          backgroundColor: Colors.redAccent[400],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "BAS EK KADAM AUR",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Aapka Naam Kya Hai?",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Bhai, apna naam bata do taaki hum aapka hisaab sahi se rakh sakein.",
                style: TextStyle(fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey),
              ),
              const SizedBox(height: 40),

              // Input field
              CustomTextField(
                controller: _nameController,
                hintText: "Yahan likhein...",
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveNameAndGo(),
              ),
              const SizedBox(height: 40),

              // Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _saveNameAndGo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "DASHBOARD CHALEIN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
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

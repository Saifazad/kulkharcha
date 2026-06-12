import 'package:flutter/material.dart';
import 'package:kulkharcha/features/onboarding/setup_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/color_constants.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isProcessing = false;

  // Helper method for modern status icons
  String _getStatusIcon(PermissionStatus? status) {
    if (status == PermissionStatus.granted) return '✅';
    if (status == PermissionStatus.denied) return '❌';
    if (status == PermissionStatus.permanentlyDenied) return '🚫';
    if (status == PermissionStatus.limited) return '🔒';
    return '⏳';
  }

  // Modern badge for compact logging
  String _getBadge(PermissionStatus? status) {
    switch (status) {
      case PermissionStatus.granted:
        return '✓ GRANTED';
      case PermissionStatus.denied:
        return '✗ DENIED';
      case PermissionStatus.permanentlyDenied:
        return '⚠ BLOCKED';
      case PermissionStatus.limited:
        return '🔒 LIMITED';
      default:
        return '? UNKNOWN';
    }
  }

  // Senior Dev Core Pipeline: Requesting SMS, Location, and Notification permissions
  Future<void> _requestAppPermissions() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Native Framework Toggles Triggering
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.location,
      Permission.notification,
    ].request();

    // 🚀 MODERN VERIFICATION LOGS - Option 1: Detailed Visual
    print('\n═══════════════════════════════════════════════');
    print('🔐 PERMISSION VERIFICATION STATUS');
    print('═══════════════════════════════════════════════');

    final smsStatus = statuses[Permission.sms];
    final locationStatus = statuses[Permission.location];
    final notificationStatus = statuses[Permission.notification];

    print(
      '📱 SMS         : ${_getStatusIcon(smsStatus)} ${smsStatus?.toString().split('.').last.toUpperCase()}',
    );
    print(
      '📍 LOCATION    : ${_getStatusIcon(locationStatus)} ${locationStatus?.toString().split('.').last.toUpperCase()}',
    );
    print(
      '🔔 NOTIFICATION: ${_getStatusIcon(notificationStatus)} ${notificationStatus?.toString().split('.').last.toUpperCase()}',
    );

    // Modern summary with counter
    final grantedCount = [
      smsStatus == PermissionStatus.granted,
      locationStatus == PermissionStatus.granted,
      notificationStatus == PermissionStatus.granted,
    ].where((e) => e == true).length;

    print('───────────────────────────────────────────────');
    print('📊 SUMMARY: $grantedCount/3 permissions granted');

    if (grantedCount == 3) {
      print('✅ All permissions granted! Proceeding to setup...');
    } else if (grantedCount >= 2) {
      print('⚠️  Partial permissions granted. Some features may be limited.');
    } else {
      print(
        '❌ Insufficient permissions. Please grant permissions for full functionality.',
      );
    }
    print('═══════════════════════════════════════════════\n');

    // 🎯 Alternative: Ultra-modern compact log (uncomment if preferred)
    // debugPrint('🔐 PERMISSIONS | SMS: ${_getBadge(smsStatus)} | LOCATION: ${_getBadge(locationStatus)} | NOTIFICATION: ${_getBadge(notificationStatus)} | GRANTED: $grantedCount/3');

    // Flagging setup completion locally (Safe from any cloud/network sync)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    if (!mounted) return;

    // Smooth entry into the main application architecture dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              // Security Premium Badge Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : AppColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Suraksha Aur Auto-Tracking Permissions",
                style:
                    Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ) ??
                    TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                "KulKharcha ek 100% offline aur privacy-first app hai. Aapka koi bhi data kisi server par nahi jata. App ko chalane ke liye niche di gayi permissions zaroori hain:",
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Permissions Showcase Grid/List Stack
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildPermissionCard(
                      icon: Icons.sms_rounded,
                      title: "SMS Read Permission",
                      description:
                          "Aapke bank transactions ke SMS auto-detect karke kharcha apne aap record karne ke liye.",
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionCard(
                      icon: Icons.location_on_rounded,
                      title: "Location Tracking Access",
                      description:
                          "Kharcha karte waqt automatic geo-tagging ke liye taaki aapko yaad rahe ki kharcha kahan hua tha.",
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionCard(
                      icon: Icons.notifications_active_rounded,
                      title: "Smart Notifications Alert",
                      description:
                          "Daily limits, budget breaches, aur automation summaries ke reminders bhejne ke liye.",
                    ),
                  ],
                ),
              ),

              // Bottom Sheet Simulation Actions
              Center(
                child: Text(
                  "🔒 No Cloud • No Internet Needed • 100% Safe",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isProcessing ? null : _requestAppPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: AppColors.textLight,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Samajh Gaya, Allow Karein",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : AppColors.borderLight,
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                : AppColors.softGreen,
            radius: 22,
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

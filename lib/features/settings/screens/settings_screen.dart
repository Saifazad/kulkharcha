import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../home/widgets/budget_settings_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final Future<void> Function() onRefreshParent;

  const SettingsScreen({
    super.key,
    required this.onRefreshParent,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = "User";
  double _dailyLimit = 1000.0;
  double _monthlyLimit = 20000.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('user_name') ?? 'User';
        _dailyLimit = prefs.getDouble('daily_budget_limit') ?? 1000.0;
        _monthlyLimit = prefs.getDouble('monthly_budget_limit') ?? 20000.0;
      });
    } catch (e) {
      debugPrint("❌ Failed to load settings: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBudgetLimits(double daily, double monthly) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('daily_budget_limit', daily);
    await prefs.setDouble('monthly_budget_limit', monthly);
    setState(() {
      _dailyLimit = daily;
      _monthlyLimit = monthly;
    });
    await widget.onRefreshParent();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Budget limits saved!"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _launchGitHub() async {
    final url = Uri.parse("https://github.com/saifazad/kulkharcha");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw "Could not launch $url";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Link open nahi ho paya: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Card
                  _buildProfileCard(),
                  const SizedBox(height: 25),

                  // Privacy & Trust Card (Highlights 100% offline, local, serverless nature)
                  _buildTrustCard(),
                  const SizedBox(height: 25),

                  // Diagnostics / Trust Verification Card
                  _buildDiagnosticsCard(),
                  const SizedBox(height: 25),

                  // Open Source & GitHub Card
                  _buildGitHubCard(),
                  const SizedBox(height: 25),

                  // Preferences Card
                  _buildPreferencesCard(),
                  const SizedBox(height: 40),

                  // Version Text
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "KulKharcha App",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "v1.0.0 • Open Source • MIT License",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            radius: 30,
            child: const Text(
              "👤",
              style: TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Local Profile Account",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Edit Profile Name",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: "Profile Name",
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            hintText: "Enter your name...",
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2D2D2D)
                : Colors.grey[50],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.grey[200]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', newName);
                setState(() {
                  _userName = newName;
                });
                await widget.onRefreshParent();
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("✅ Profile name updated successfully!"),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
              }
            },
            child: Text(
              "Save",
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "100% Offline & Private",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Local Safe",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTrustPoint(
            icon: Icons.cloud_off_rounded,
            title: "Without Server & Internet",
            description: "App ko chalne ke liye koi internet ya server network connection nahi chahiye. Poora calculation offline hota hai.",
          ),
          const Divider(color: Colors.white24, height: 24),
          _buildTrustPoint(
            icon: Icons.storage_rounded,
            title: "Zero Data Upload",
            description: "Aapka data local SQLite database mein save hota hai. Hamara koi centralized database server nahi hai, isliye data leak hone ka koi chance nahi.",
          ),
          const Divider(color: Colors.white24, height: 24),
          _buildTrustPoint(
            icon: Icons.security_rounded,
            title: "No Account Required",
            description: "App use karne ke liye kisi login, password ya account details ki zaroorat nahi hai. Privacy safe.",
          ),
        ],
      ),
    );
  }

  Widget _buildTrustPoint({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGitHubCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchGitHub,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
                  radius: 22,
                  child: const Text(
                    "💻",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Open Source GitHub Code",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Trust verify karne ke liye code review karein",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              radius: 16,
              child: Icon(
                Icons.settings_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
            ),
            title: const Text(
              "Set Daily & Monthly Limits",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              BudgetSettingsSheet.show(
                context,
                dailyLimit: _dailyLimit,
                monthlyLimit: _monthlyLimit,
                onSave: _saveBudgetLimits,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Privacy & Network Diagnostics",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildDiagRow(
            icon: Icons.storage_outlined,
            label: "Local Database (SQLite)",
            value: "Healthy & Active",
            valueColor: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildDiagRow(
            icon: Icons.language_outlined,
            label: "Internet Data Sent",
            value: "0.00 KB (Zero Outgoing)",
            valueColor: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildDiagRow(
            icon: Icons.dns_outlined,
            label: "Remote Server Host",
            value: "Not Configured",
            valueColor: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _showVerificationDialog,
              icon: Icon(Icons.help_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
              label: Text(
                "Verify Privacy Manually (Aap Kaise Check Karein?)",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text("🛡️ ", style: TextStyle(fontSize: 20)),
            Text(
              "Privacy Self-Test Guide",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Aap khud check kar sakte hain ki aapka data kahi upload nahi ho raha:",
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              _buildGuidePoint(
                step: "1",
                title: "Flight Mode Test",
                desc: "Phone ka Internet / Wi-Fi band karke app ko use karein. App ke saare calculations, parsing aur database features bina kisi warning ke 100% normal chalenge.",
              ),
              const SizedBox(height: 12),
              _buildGuidePoint(
                step: "2",
                title: "Open Source Code Review",
                desc: "Hamaara code open-source hai. Aap GitHub par pure code ko search kar sakte hain — isme koi internet network api request code built-in nahi milega.",
              ),
              const SizedBox(height: 12),
              _buildGuidePoint(
                step: "3",
                title: "Local Database File location",
                desc: "Sare transactions aapke device ke local SQLite storage path 'databases/kulkharcha.db' ke andar securely write aur read hote hain.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "Samajh Gaya",
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidePoint({
    required String step,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          radius: 10,
          child: Text(
            step,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

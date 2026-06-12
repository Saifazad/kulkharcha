import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/database/database_helper.dart';
import '../../../services/sms_service.dart';
import '../widgets/home_header.dart';
import '../widgets/budget_card.dart';
import '../widgets/budget_settings_sheet.dart';
import '../widgets/category_section.dart';
import '../widgets/recent_transactions_list.dart';
import '../../history/screens/history_screen.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../settings/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // ── State ──────────────────────────────────────────────────────────────────
  String _userName = "User";
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _categoryExpenses = {};
  double _todayExpense = 0.0;
  double _monthlyExpense = 0.0;
  double _dailyLimit = 1000.0;
  double _monthlyLimit = 20000.0;
  bool _showMonthly = false;
  bool _isLoading = true;
  bool _isSmsPermissionGranted = true;
  int _currentIndex = 0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPrefs();
    _checkPermissionStatus(); // SMS permission status check karein
    _fetchData();
    _syncAndFetch(); // App startup par ek baar inbox sync karein
    _startRealtimeListener(); // 📡 Instant SMS detection
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatus(); // settings se return hone par status refresh karein
      _syncAndFetch(); // App resume hone par ek baar sync karein
    }
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.sms.status;
    if (mounted) {
      setState(() {
        _isSmsPermissionGranted = status.isGranted;
      });
    }
  }

  // ── Data loading ───────────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _dailyLimit = prefs.getDouble('daily_budget_limit') ?? 1000.0;
      _monthlyLimit = prefs.getDouble('monthly_budget_limit') ?? 20000.0;
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      await _loadPrefs();
      final tx = await DatabaseHelper.instance.getAllTransactions();
      final cat = await DatabaseHelper.instance.getCategoryWiseExpenses();
      _updateState(tx, cat);
    } catch (e) {
      debugPrint("❌ Fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncAndFetch() async {
    try {
      await SMSService().fetchAndParseSMS();
      final tx = await DatabaseHelper.instance.getAllTransactions();
      final cat = await DatabaseHelper.instance.getCategoryWiseExpenses();
      if (mounted) _updateState(tx, cat);
    } catch (e) {
      debugPrint("Auto sync error: $e");
    }
  }

  // 📡 Real-time SMS listener — koi bhi bank SMS aate hi UI instantly refresh ho
  void _startRealtimeListener() {
    SMSService().startRealtimeListener(
      onNewTransaction: () async {
        // SMS se naya transaction aaya — DB se fresh data lo aur UI update karo
        final tx = await DatabaseHelper.instance.getAllTransactions();
        final cat = await DatabaseHelper.instance.getCategoryWiseExpenses();
        if (mounted) {
          _updateState(tx, cat);
          debugPrint("🔄 [Real-time] UI instantly update ho gaya!");
        }
      },
    );
  }

  void _updateState(List<Map<String, dynamic>> tx, Map<String, double> cat) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final monthPrefix = DateFormat('yyyy-MM').format(now);
    double today = 0, month = 0;
    for (final t in tx) {
      final d = t['date']?.toString() ?? '';
      final a = (t['amount'] as num).toDouble();
      if (d.startsWith(todayStr)) today += a;
      if (d.startsWith(monthPrefix)) month += a;
    }
    setState(() {
      _transactions = tx;
      _categoryExpenses = cat;
      _todayExpense = today;
      _monthlyExpense = month;
      _isLoading = false;
    });
  }

  // ── Budget helpers ─────────────────────────────────────────────────────────
  Future<void> _saveBudgetLimits(double daily, double monthly) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('daily_budget_limit', daily);
    await prefs.setDouble('monthly_budget_limit', monthly);
    setState(() {
      _dailyLimit = daily;
      _monthlyLimit = monthly;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Budget limits saved!"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  // ── Merchant title helper (used by RecentTransactionsList) ─────────────────
  String _getCleanTitle(String category, String? description) {
    if (description == null || description.isEmpty) return category;
    final text = description.toLowerCase();
    const brands = {
      'zomato': 'Zomato',
      'swiggy': 'Swiggy',
      'meesho': 'Meesho',
      'amazon': 'Amazon',
      'flipkart': 'Flipkart',
      'myntra': 'Myntra',
      'zara': 'Zara',
      'starbucks': 'Starbucks',
      'netflix': 'Netflix',
      'spotify': 'Spotify',
      'jio': 'Jio Recharge',
      'airtel': 'Airtel',
      'apollo': 'Apollo Pharmacy',
      'pharmacy': 'Apollo Pharmacy',
      'atm': 'ATM Cash',
      'withdrawal': 'ATM Cash',
    };
    for (final entry in brands.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    if (text.contains('petrol') ||
        text.contains('diesel') ||
        text.contains('fuel') ||
        text.contains('hpcl') ||
        text.contains('bpcl')) {
      return 'Petrol Pump';
    }
    final patterns = [
      RegExp(r'spent\s+at\s+([a-zA-Z0-9\s\-\.&]+)', caseSensitive: false),
      RegExp(r'spent\s+on\s+([a-zA-Z0-9\s\-\.&]+)', caseSensitive: false),
      RegExp(r'paid\s+to\s+([a-zA-Z0-9\s\-\.&]+)', caseSensitive: false),
      RegExp(r'sent\s+to\s+([a-zA-Z0-9\s\-\.&]+)', caseSensitive: false),
      RegExp(r'transferred\s+to\s+([a-zA-Z0-9\s\-\.&]+)', caseSensitive: false),
      RegExp(r'\bto\s+([a-zA-Z0-9\s\-\.&]+)', caseSensitive: false),
      RegExp(r'at\s+([a-zA-Z0-9\s\-\.&]+)', caseSensitive: false),
    ];
    for (final regex in patterns) {
      final match = regex.firstMatch(description);
      if (match != null) {
        var raw = match.group(1)!;
        if (raw.contains('.')) raw = raw.split('.')[0];
        const stops = [
          'debited',
          'on',
          'from',
          'using',
          'ref',
          'card',
          'a/c',
          'xx',
          'with',
          'via',
          'through',
          'for',
          'at',
        ];
        for (final stop in stops) {
          final m = RegExp('\\b$stop\\b', caseSensitive: false).firstMatch(raw);
          if (m != null) raw = raw.substring(0, m.start);
        }
        raw = raw
            .replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), '')
            .trim();
        if (raw.length > 1) {
          return raw
              .split(RegExp(r'\s+'))
              .map(
                (w) => w.isEmpty
                    ? ''
                    : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
              )
              .join(' ');
        }
      }
    }
    return category == 'General' ? 'Transaction' : category;
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _syncAndFetch,
      color: Theme.of(context).colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            HomeHeader(userName: _userName),
            const SizedBox(height: 25),
            if (!_isSmsPermissionGranted) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.red.withOpacity(0.15)
                      : const Color(0xFFFEEBEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.red.withOpacity(0.3)
                        : const Color(0xFFFFCDD2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.red[300]
                          : const Color(0xFFC62828),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "SMS Permission blocked hai. Auto-tracking active nahi hai.",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.red[200]
                              : const Color(0xFFC62828),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => openAppSettings(),
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.red[700]
                            : const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text(
                        "Settings",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ],
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            else ...[
              BudgetCard(
                todayExpense: _todayExpense,
                monthlyExpense: _monthlyExpense,
                dailyLimit: _dailyLimit,
                monthlyLimit: _monthlyLimit,
                showMonthly: _showMonthly,
                onToggleDaily: () => setState(() => _showMonthly = false),
                onToggleMonthly: () => setState(() => _showMonthly = true),
                onSettingsTap: () => BudgetSettingsSheet.show(
                  context,
                  dailyLimit: _dailyLimit,
                  monthlyLimit: _monthlyLimit,
                  onSave: _saveBudgetLimits,
                ),
              ),
              const SizedBox(height: 30),
              CategorySection(categoryExpenses: _categoryExpenses),
              const SizedBox(height: 30),
              RecentTransactionsList(
                transactions: _transactions,
                getCleanTitle: _getCleanTitle,
                onRefresh: _fetchData,
                onViewAll: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_currentIndex) {
      case 0:
        bodyContent = _buildHomeTab();
        break;
      case 1:
        bodyContent = HistoryScreen(
          onRefreshParent: _fetchData,
          getCleanTitle: _getCleanTitle,
        );
        break;
      case 2:
        bodyContent = AnalyticsScreen(
          onRefreshParent: _fetchData,
          getCleanTitle: _getCleanTitle,
        );
        break;
      case 3:
        bodyContent = SettingsScreen(
          onRefreshParent: _fetchData,
        );
        break;
      default:
        bodyContent = _buildHomeTab();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: bodyContent),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            _loadPrefs();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: "Analytics",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}

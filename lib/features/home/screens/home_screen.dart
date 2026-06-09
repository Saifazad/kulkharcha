import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../data/database/database_helper.dart';
import '../../../services/sms_service.dart';
import '../widgets/home_header.dart';
import '../widgets/budget_card.dart';
import '../widgets/budget_settings_sheet.dart';
import '../widgets/category_section.dart';
import '../widgets/recent_transactions_list.dart';

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

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPrefs();
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
      _syncAndFetch(); // App resume hone par ek baar sync karein
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
        const SnackBar(
          content: Text("✅ Budget limits saved!"),
          backgroundColor: Color(0xFF1B5E20),
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _syncAndFetch,
          color: const Color(0xFF1B5E20),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                HomeHeader(userName: _userName),
                const SizedBox(height: 25),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1B5E20),
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
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF1B5E20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1B5E20),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        currentIndex: 0,
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

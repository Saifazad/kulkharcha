import 'package:flutter/material.dart';

// ── Insight model ─────────────────────────────────────────────────────────────

class SpendingInsight {
  final String emoji;
  final String title;
  final String message;
  final Color color;
  final InsightSeverity severity;

  const SpendingInsight({
    required this.emoji,
    required this.title,
    required this.message,
    required this.color,
    required this.severity,
  });
}

enum InsightSeverity { info, warning, danger }

// ── Analysis Engine ───────────────────────────────────────────────────────────

class KulkAIEngine {
  /// Frivolous categories / merchant keywords that indicate impulse spending
  static const _impulsiveKeywords = [
    'swiggy',
    'zomato',
    'blinkit',
    'zepto',
    'bigbasket',
    'amazon',
    'flipkart',
    'meesho',
    'myntra',
    'ajio',
    'instamart',
    'dunzo',
  ];

  static const _categoryPriority = {
    'Food & Groceries': 1,
    'Shopping': 2,
    'Fuel & Transport': 3,
    'Medical & Health': 4,
    'Bills & Recharges': 5,
    'Kheti/Farming': 6,
    'Cash (ATM)': 7,
    'General': 8,
  };

  /// Main method — returns list of insights based on today's transactions
  static List<SpendingInsight> analyze({
    required List<Map<String, dynamic>> transactions,
    required double dailyLimit,
    required double todayExpense,
  }) {
    if (transactions.isEmpty) return [];

    // Filter today's transactions
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayTx = transactions.where((t) {
      final d = t['date']?.toString() ?? '';
      return d.startsWith(todayStr);
    }).toList();

    if (todayTx.isEmpty) return [];

    final insights = <SpendingInsight>[];

    // 1. Budget exceeded analysis
    if (todayExpense > dailyLimit) {
      final overflow = todayExpense - dailyLimit;
      insights.add(_budgetExceededInsight(todayTx, overflow, dailyLimit));
    } else if (todayExpense > dailyLimit * 0.80) {
      final percent = ((todayExpense / dailyLimit) * 100).round();
      final remaining = dailyLimit - todayExpense;
      insights.add(
        SpendingInsight(
          emoji: '⚠️',
          title: 'Budget Almost Full!',
          message:
              'Aaj ka budget $percent% use ho gaya hai. Sirf ₹${remaining.toStringAsFixed(0)} bacha hai — careful rahein!',
          color: const Color(0xFFFF6F00),
          severity: InsightSeverity.warning,
        ),
      );
    }

    // 2. Impulse / delivery spending detection
    final impulseInsight = _detectImpulseSpending(todayTx);
    if (impulseInsight != null) insights.add(impulseInsight);

    // 3. Top category analysis
    final categoryInsight = _topCategoryInsight(todayTx);
    if (categoryInsight != null) insights.add(categoryInsight);

    // 4. Repeated small transactions
    final repeatedInsight = _detectRepeatedSmallTx(todayTx);
    if (repeatedInsight != null) insights.add(repeatedInsight);

    // 5. Largest single transaction
    final largestInsight = _largestTransactionInsight(todayTx);
    if (largestInsight != null) insights.add(largestInsight);

    return insights;
  }

  // ── Private analyzers ────────────────────────────────────────────────────

  static SpendingInsight _budgetExceededInsight(
    List<Map<String, dynamic>> todayTx,
    double overflow,
    double limit,
  ) {
    // Find the biggest spending category today
    final categoryTotals = <String, double>{};
    for (final t in todayTx) {
      final cat = t['category'] as String? ?? 'General';
      categoryTotals[cat] =
          (categoryTotals[cat] ?? 0) + (t['amount'] as num).toDouble();
    }
    MapEntry<String, double> topCategory = categoryTotals.entries.first;
    for (final entry in categoryTotals.entries) {
      if (entry.value > topCategory.value) {
        topCategory = entry;
      }
    }

    final wastefulMessages = {
      'Food & Groceries':
          'Aaj ka sabse bada kharcha **${topCategory.key}** pe tha — ₹${topCategory.value.toStringAsFixed(0)}. Ghar ka khana try karo, paisa bachega! 🍱',
      'Shopping':
          'Shopping pe ₹${topCategory.value.toStringAsFixed(0)} kharch kiya aaj. Har cheez zaruri nahi hoti! 🛍️',
      'Fuel & Transport':
          'Fuel/Transport pe ₹${topCategory.value.toStringAsFixed(0)} gaya. Carpooling ya public transport try karo. 🚌',
      'General':
          '₹${topCategory.value.toStringAsFixed(0)} unplanned kharch hua **${topCategory.key}** pe. Next time budget plan karo!',
    };

    final msg =
        wastefulMessages[topCategory.key] ??
        'Budget ₹${overflow.toStringAsFixed(0)} se exceed ho gayi! Sabse bada kharcha ${topCategory.key} pe — ₹${topCategory.value.toStringAsFixed(0)}.';

    return SpendingInsight(
      emoji: '🚨',
      title: 'Budget Exceed Ho Gayi!',
      message: msg,
      color: const Color(0xFFD32F2F),
      severity: InsightSeverity.danger,
    );
  }

  static SpendingInsight? _detectImpulseSpending(
    List<Map<String, dynamic>> todayTx,
  ) {
    double impulseTotal = 0.0;
    final impulseApps = <String>{};

    for (final t in todayTx) {
      final desc = (t['description'] as String? ?? '').toLowerCase();
      for (final keyword in _impulsiveKeywords) {
        if (desc.contains(keyword)) {
          impulseTotal += (t['amount'] as num).toDouble();
          impulseApps.add(_capitalize(keyword));
          break;
        }
      }
    }

    if (impulseTotal == 0) return null;

    final apps = impulseApps.take(2).join(', ');
    return SpendingInsight(
      emoji: '📱',
      title: 'Online Orders Pe Nazar Rakh!',
      message:
          'Aaj aapne $apps jaise apps pe ₹${impulseTotal.toStringAsFixed(0)} kharch kiye. Ye "thoda order kar lo" wali aadat mehengi padti hai!',
      color: const Color(0xFF1565C0),
      severity: InsightSeverity.warning,
    );
  }

  static SpendingInsight? _topCategoryInsight(
    List<Map<String, dynamic>> todayTx,
  ) {
    if (todayTx.length < 2) return null;

    final categoryTotals = <String, double>{};
    for (final t in todayTx) {
      final cat = t['category'] as String? ?? 'General';
      categoryTotals[cat] =
          (categoryTotals[cat] ?? 0) + (t['amount'] as num).toDouble();
    }

    if (categoryTotals.length < 2) return null;

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.first;
    final totalToday = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final percent = ((top.value / totalToday) * 100).round();

    if (percent < 40) return null; // Only show if one category dominates

    return SpendingInsight(
      emoji: '📊',
      title: 'Spending Pattern',
      message:
          'Aaj ka $percent% kharcha sirf **${top.key}** pe gaya (₹${top.value.toStringAsFixed(0)}). Ek category pe itna focus theek nahi!',
      color: const Color(0xFF6A1B9A),
      severity: InsightSeverity.info,
    );
  }

  static SpendingInsight? _detectRepeatedSmallTx(
    List<Map<String, dynamic>> todayTx,
  ) {
    final smallTx = todayTx
        .where((t) => (t['amount'] as num).toDouble() < 200)
        .toList();
    if (smallTx.length < 3) return null;

    final totalSmall = smallTx.fold(
      0.0,
      (sum, t) => sum + (t['amount'] as num).toDouble(),
    );

    return SpendingInsight(
      emoji: '💸',
      title: 'Chota Chota, Bada Nuksaan!',
      message:
          'Aaj ${smallTx.length} baar ₹200 se kam transactions kiye — total mila ke ₹${totalSmall.toStringAsFixed(0)}. Ye "chhoti" purchases badi quickly add up karti hain!',
      color: const Color(0xFF00695C),
      severity: InsightSeverity.info,
    );
  }

  static SpendingInsight? _largestTransactionInsight(
    List<Map<String, dynamic>> todayTx,
  ) {
    if (todayTx.isEmpty) return null;
    Map<String, dynamic> largest = todayTx.first;
    for (final t in todayTx) {
      final amountT = (t['amount'] as num).toDouble();
      final amountLargest = (largest['amount'] as num).toDouble();
      if (amountT > amountLargest) {
        largest = t;
      }
    }
    final amount = (largest['amount'] as num).toDouble();
    if (amount < 500) return null;

    final desc = largest['description'] as String? ?? '';
    final merchant = _extractMerchantName(desc);

    return SpendingInsight(
      emoji: '💰',
      title: 'Sabse Bada Transaction Aaj',
      message:
          'Aaj ki sabse badi payment: ₹${amount.toStringAsFixed(0)} ${merchant.isNotEmpty ? "($merchant)" : ""}. Ye zaruri tha?',
      color: const Color(0xFF1B5E20),
      severity: InsightSeverity.info,
    );
  }

  static String _extractMerchantName(String desc) {
    final text = desc.toLowerCase();
    for (final k in _impulsiveKeywords) {
      if (text.contains(k)) return _capitalize(k);
    }
    final toMatch = RegExp(
      r'to\s+([a-zA-Z0-9\s]+)\s+on',
      caseSensitive: false,
    ).firstMatch(desc);
    if (toMatch != null) {
      return toMatch.group(1)?.trim().split(' ').first ?? '';
    }
    return '';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── UI Widget ─────────────────────────────────────────────────────────────────

class SmartInsightCard extends StatefulWidget {
  final List<SpendingInsight> insights;

  const SmartInsightCard({super.key, required this.insights});

  @override
  State<SmartInsightCard> createState() => _SmartInsightCardState();
}

class _SmartInsightCardState extends State<SmartInsightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < widget.insights.length - 1) {
      _controller.reverse().then((_) {
        setState(() => _currentIndex++);
        _controller.forward();
      });
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      _controller.reverse().then((_) {
        setState(() => _currentIndex--);
        _controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.insights.isEmpty) return const SizedBox.shrink();

    final insight = widget.insights[_currentIndex];

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [insight.color, insight.color.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: insight.color.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: KulkAI badge + nav dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Text('🤖', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text(
                            'KulkAI Insight',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.insights.length > 1)
                      Row(
                        children: List.generate(
                          widget.insights.length,
                          (i) => Container(
                            width: i == _currentIndex ? 16 : 6,
                            height: 6,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: i == _currentIndex
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Emoji + Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insight.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            insight.message.replaceAll('**', ''),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Navigation arrows if multiple insights
                if (widget.insights.length > 1) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_currentIndex > 0)
                        GestureDetector(
                          onTap: _prev,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Pehle wala',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (_currentIndex < widget.insights.length - 1)
                        GestureDetector(
                          onTap: _next,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'Agle insight',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

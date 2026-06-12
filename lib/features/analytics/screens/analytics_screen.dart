import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../data/database/database_helper.dart';
import '../../home/widgets/transaction_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  final Future<void> Function() onRefreshParent;
  final String Function(String category, String? desc) getCleanTitle;

  const AnalyticsScreen({
    super.key,
    required this.onRefreshParent,
    required this.getCleanTitle,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedRange = 'This Week'; // 'This Week', 'This Month', 'All Time'
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  // Chart data calculations
  double _totalSpend = 0.0;
  double _dailyAverage = 0.0;
  Map<String, double> _categoryTotals = {};
  List<double> _trendPoints = [];
  List<String> _trendLabels = [];

  late final AnimationController _animationController;
  late final Animation<double> _chartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _chartScaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final txs = await DatabaseHelper.instance.getAllTransactions();
      _transactions = txs;
      _computeStatistics();
      _animationController.forward(from: 0.0);
    } catch (e) {
      debugPrint("❌ Analytics fetch error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _computeStatistics() {
    final now = DateTime.now();
    DateTime filterCutoff;

    if (_selectedRange == 'This Week') {
      // Last 7 days including today
      filterCutoff = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));
    } else if (_selectedRange == 'This Month') {
      // Last 30 days
      filterCutoff = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 29));
    } else {
      // All time
      filterCutoff = DateTime(2000); // far back
    }

    final filteredTxs = _transactions.where((tx) {
      final dateStr = tx['date'] as String? ?? '';
      if (dateStr.isEmpty) return false;
      try {
        final date = DateTime.parse(dateStr);
        return date.isAfter(filterCutoff) ||
            date.isAtSameMomentAs(filterCutoff);
      } catch (_) {
        return false;
      }
    }).toList();

    // Calculate totals and categories
    double sum = 0.0;
    final Map<String, double> catMap = {};
    for (final tx in filteredTxs) {
      final amount = (tx['amount'] as num).toDouble();
      final cat = tx['category'] as String? ?? 'General';
      sum += amount;
      catMap[cat] = (catMap[cat] ?? 0.0) + amount;
    }

    _totalSpend = sum;
    _categoryTotals = catMap;

    // Calculate daily average and trend points
    if (_selectedRange == 'This Week') {
      _dailyAverage = sum / 7;
      _buildDailyTrend(7);
    } else if (_selectedRange == 'This Month') {
      _dailyAverage = sum / 30;
      _buildDailyTrend(30);
    } else {
      // All time - get count of unique active days
      final uniqueDays = _transactions
          .map((tx) {
            final dateStr = tx['date'] as String? ?? '';
            return dateStr.split('T').first;
          })
          .toSet()
          .length;

      _dailyAverage = uniqueDays > 0 ? sum / uniqueDays : sum;
      _buildAllTimeTrend();
    }
  }

  void _buildDailyTrend(int daysCount) {
    final now = DateTime.now();
    final List<double> dailyTotals = List.filled(daysCount, 0.0);
    final List<String> labels = [];

    // Prepopulate date list in ascending order
    final List<String> dayKeys = [];
    for (int i = daysCount - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dayKeys.add(DateFormat('yyyy-MM-dd').format(date));

      if (daysCount == 7) {
        labels.add(DateFormat('E').format(date)); // Mon, Tue, etc.
      } else {
        // Show labels every 5 days for monthly
        if (i % 5 == 0) {
          labels.add(DateFormat('d MMM').format(date));
        } else {
          labels.add('');
        }
      }
    }

    for (final tx in _transactions) {
      final dateStr = tx['date'] as String? ?? '';
      if (dateStr.isEmpty) continue;
      final dayKey = dateStr.split('T').first;
      final idx = dayKeys.indexOf(dayKey);
      if (idx != -1) {
        dailyTotals[idx] += (tx['amount'] as num).toDouble();
      }
    }

    _trendPoints = dailyTotals;
    _trendLabels = labels;
  }

  void _buildAllTimeTrend() {
    // Group by month for all time trend
    final Map<String, double> monthlyTotals = {};
    final now = DateTime.now();

    // Fetch last 6 months
    final List<String> monthKeys = [];
    final List<String> labels = [];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('yyyy-MM').format(d);
      monthKeys.add(key);
      labels.add(DateFormat('MMM').format(d));
      monthlyTotals[key] = 0.0;
    }

    for (final tx in _transactions) {
      final dateStr = tx['date'] as String? ?? '';
      if (dateStr.isEmpty) continue;
      final monthKey = dateStr.substring(0, 7); // yyyy-MM
      if (monthlyTotals.containsKey(monthKey)) {
        monthlyTotals[monthKey] =
            monthlyTotals[monthKey]! + (tx['amount'] as num).toDouble();
      }
    }

    _trendPoints = monthKeys.map((k) => monthlyTotals[k]!).toList();
    _trendLabels = labels;
  }

  @override
  Widget build(BuildContext context) {
    // Sort categories by expenditure
    final sortedCategories = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Analytics",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalyticsData,
              color: Theme.of(context).colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time filter Selector
                    _buildRangeSelector(),
                    const SizedBox(height: 20),

                    // Metrics Grid (Total Spend + Daily Average)
                    _buildMetricsGrid(),
                    const SizedBox(height: 25),

                    // Spending Trend Chart (Custom Spline Graph)
                    _buildSpendingTrendCard(),
                    const SizedBox(height: 25),

                    // Category Breakdown Card (Donut Chart)
                    if (_totalSpend > 0) ...[
                      _buildCategoryDistributionCard(sortedCategories),
                      const SizedBox(height: 25),

                      // Detailed Category Progress Bars
                      _buildCategoryDetailsList(sortedCategories),
                    ] else
                      _buildEmptyChartState(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: ['This Week', 'This Month', 'All Time'].map((range) {
          final isSelected = _selectedRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRange = range;
                  _computeStatistics();
                  _animationController.forward(from: 0.0);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  range,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: "Total Spent",
            value: "₹${_totalSpend.toStringAsFixed(0)}",
            icon: Icons.account_balance_wallet,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile(
            title: "Daily Average",
            value: "₹${_dailyAverage.toStringAsFixed(0)}",
            icon: Icons.trending_up,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 18,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendCard() {
    final maxVal = _trendPoints.isNotEmpty
        ? _trendPoints.reduce(math.max)
        : 0.0;

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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Spending Trend",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Highest transaction day touched ₹${maxVal.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _chartScaleAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 160),
                painter: TrendLineChartPainter(
                  points: _trendPoints,
                  labels: _trendLabels,
                  animationProgress: _chartScaleAnimation.value,
                  lineColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistributionCard(List<MapEntry<String, double>> sorted) {
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Category Distribution",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 140,
                  child: AnimatedBuilder(
                    animation: _chartScaleAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: DonutChartPainter(
                          categoryTotals: _categoryTotals,
                          totalSpend: _totalSpend,
                          animationProgress: _chartScaleAnimation.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sorted.take(3).map((entry) {
                    final percentage = (entry.value / _totalSpend) * 100;
                    final style = resolveCategoryStyle(entry.key);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: style.iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "${percentage.toStringAsFixed(0)}%",
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDetailsList(List<MapEntry<String, double>> sorted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            "Expense Breakdown",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = sorted[index];
            final percent = entry.value / _totalSpend;
            final style = resolveCategoryStyle(entry.key);

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? style.iconColor.withOpacity(0.15)
                            : style.bgColor,
                        radius: 18,
                        child: Icon(
                          style.icon,
                          color: style.iconColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${entry.value.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "${(percent * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Premium modern progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF242424)
                              : Colors.grey[100],
                        ),
                        AnimatedBuilder(
                          animation: _chartScaleAnimation,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor: percent * _chartScaleAnimation.value,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: style.iconColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyChartState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Column(
          children: [
            Text("📊", style: TextStyle(fontSize: 40)),
            SizedBox(height: 16),
            Text(
              "Graph dikhane ke liye data kam hai.",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              "Naya bank message aane par graph automatically ban jayega.",
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Donut Chart Painter ───────────────────────────────────────────────

class DonutChartPainter extends CustomPainter {
  final Map<String, double> categoryTotals;
  final double totalSpend;
  final double animationProgress;

  DonutChartPainter({
    required this.categoryTotals,
    required this.totalSpend,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalSpend == 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2;

    final rect = Rect.fromCircle(center: center, radius: radius - 15);

    categoryTotals.forEach((category, value) {
      final percentage = value / totalSpend;
      final sweepAngle = percentage * 2 * math.pi * animationProgress;

      final style = resolveCategoryStyle(category);

      final paint = Paint()
        ..color = style.iconColor
        ..strokeWidth = 18.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw a tiny spacing gap between segments to look extremely premium
      double gap = 0.08;
      if (sweepAngle > gap) {
        canvas.drawArc(
          rect,
          startAngle + gap / 2,
          sweepAngle - gap,
          false,
          paint,
        );
      }

      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.categoryTotals != categoryTotals ||
        oldDelegate.totalSpend != totalSpend;
  }
}

// ── Custom Spline/Trend Line Painter ─────────────────────────────────────────

class TrendLineChartPainter extends CustomPainter {
  final List<double> points;
  final List<String> labels;
  final double animationProgress;
  final Color lineColor;

  TrendLineChartPainter({
    required this.points,
    required this.labels,
    required this.animationProgress,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final width = size.width;
    final height = size.height - 20; // reserve space for bottom labels

    final maxVal = points.reduce(math.max);
    final minVal = points.reduce(math.min);
    final divisor = maxVal == 0 ? 1.0 : maxVal;

    final stepX = width / (points.length - 1);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = lineColor.withOpacity(0.15)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final List<Offset> offsets = [];
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      // Invert Y axis and apply scale animation
      final progressY = (points[i] / divisor) * height * animationProgress;
      final y = height - progressY;
      offsets.add(Offset(x, y));
    }

    if (offsets.length > 1) {
      final curvePath = Path();
      curvePath.moveTo(offsets[0].dx, offsets[0].dy);

      for (int i = 0; i < offsets.length - 1; i++) {
        final p0 = offsets[i];
        final p1 = offsets[i + 1];

        // Smooth cubic control points
        final controlX = (p0.dx + p1.dx) / 2;
        curvePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }

      // 1. Draw glowing background shadow
      canvas.drawPath(curvePath, glowPaint);

      // 2. Draw gradient fill under the line
      final fillPath = Path.from(curvePath);
      fillPath.lineTo(width, height);
      fillPath.lineTo(0, height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            lineColor.withOpacity(0.25),
            lineColor.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTRB(0, 0, width, height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      // 3. Draw main line
      canvas.drawPath(curvePath, linePaint);

      // 4. Draw circular dot indicator on final point (Today)
      final activeDot = offsets.last;
      final borderPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      final innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(activeDot, 6.0, borderPaint);
      canvas.drawCircle(activeDot, 3.0, innerPaint);
    }

    // 5. Draw bottom labels
    const textStyle = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );

    for (int i = 0; i < labels.length; i++) {
      if (labels[i].isEmpty) continue;
      final x = i * stepX;
      final textSpan = TextSpan(text: labels[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      // Adjust text offset to center horizontally
      final offset = Offset(x - (textPainter.width / 2), height + 6);

      // Ensure bounds don't write out of canvas width
      final clampedX = offset.dx.clamp(0.0, width - textPainter.width);
      textPainter.paint(canvas, Offset(clampedX, offset.dy));
    }
  }

  @override
  bool shouldRepaint(covariant TrendLineChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.points != points ||
        oldDelegate.labels != labels;
  }
}

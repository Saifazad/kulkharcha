import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kulkharcha/features/home/widgets/smart_insight_card.dart';

void main() {
  group('KulkAIEngine Unit Tests', () {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    test('should return empty list when no transactions', () {
      final insights = KulkAIEngine.analyze(
        transactions: [],
        dailyLimit: 1000.0,
        todayExpense: 0.0,
      );
      expect(insights, isEmpty);
    });

    test('should detect impulse spending on Swiggy and Zomato', () {
      final transactions = [
        {
          'date': '$todayStr 13:00:00',
          'amount': 450.0,
          'category': 'Food & Groceries',
          'description': 'Paid to Zomato',
        },
      ];

      final insights = KulkAIEngine.analyze(
        transactions: transactions,
        dailyLimit: 1000.0,
        todayExpense: 450.0,
      );

      final impulseInsight = insights.firstWhere((i) => i.severity == InsightSeverity.warning);
      expect(impulseInsight.title, equals('Online Orders Pe Nazar Rakh!'));
      expect(impulseInsight.message, contains('Zomato'));
      expect(impulseInsight.emoji, equals('📱'));
    });

    test('should detect budget exceeded', () {
      final transactions = [
        {
          'date': '$todayStr 10:00:00',
          'amount': 1200.0,
          'category': 'Shopping',
          'description': 'Zara Store',
        },
      ];

      final insights = KulkAIEngine.analyze(
        transactions: transactions,
        dailyLimit: 1000.0,
        todayExpense: 1200.0,
      );

      final budgetInsight = insights.firstWhere((i) => i.severity == InsightSeverity.danger);
      expect(budgetInsight.title, equals('Budget Exceed Ho Gayi!'));
      expect(budgetInsight.message, contains('Shopping'));
      expect(budgetInsight.emoji, equals('🚨'));
    });

    test('should detect repeated small transactions', () {
      final transactions = [
        {
          'date': '$todayStr 09:00:00',
          'amount': 50.0,
          'category': 'General',
          'description': 'Chai Tapri',
        },
        {
          'date': '$todayStr 11:00:00',
          'amount': 80.0,
          'category': 'General',
          'description': 'Sutta & Tea',
        },
        {
          'date': '$todayStr 14:00:00',
          'amount': 150.0,
          'category': 'Food & Groceries',
          'description': 'Chips & Drinks',
        },
      ];

      final insights = KulkAIEngine.analyze(
        transactions: transactions,
        dailyLimit: 1000.0,
        todayExpense: 280.0,
      );

      final repeatedInsight = insights.firstWhere((i) => i.title == 'Chota Chota, Bada Nuksaan!');
      expect(repeatedInsight.emoji, equals('💸'));
      expect(repeatedInsight.message, contains('3 baar'));
    });
  });

  group('SmartInsightCard Widget Tests', () {
    testWidgets('renders single insight card correctly', (WidgetTester tester) async {
      const insight = SpendingInsight(
        emoji: '💡',
        title: 'Test Insight',
        message: 'This is a test message for tracking.',
        color: Colors.blue,
        severity: InsightSeverity.info,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartInsightCard(insights: [insight]),
          ),
        ),
      );

      // Verify that it renders elements
      expect(find.text('KulkAI Insight'), findsOneWidget);
      expect(find.text('Test Insight'), findsOneWidget);
      expect(find.text('This is a test message for tracking.'), findsOneWidget);
      expect(find.text('💡'), findsOneWidget);

      // No navigation buttons since there is only 1 insight
      expect(find.text('Agle insight'), findsNothing);
    });

    testWidgets('navigates through multiple insights', (WidgetTester tester) async {
      const insights = [
        SpendingInsight(
          emoji: '💡',
          title: 'First Insight',
          message: 'This is first.',
          color: Colors.blue,
          severity: InsightSeverity.info,
        ),
        SpendingInsight(
          emoji: '⚠️',
          title: 'Second Insight',
          message: 'This is second.',
          color: Colors.orange,
          severity: InsightSeverity.warning,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartInsightCard(insights: insights),
          ),
        ),
      );

      // Check first insight is showing
      expect(find.text('First Insight'), findsOneWidget);
      expect(find.text('Second Insight'), findsNothing);

      // Tap on "Agle insight"
      final nextButton = find.text('Agle insight');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Check second insight is showing
      expect(find.text('Second Insight'), findsOneWidget);
      expect(find.text('First Insight'), findsNothing);

      // Tap on "Pehle wala"
      final prevButton = find.text('Pehle wala');
      expect(prevButton, findsOneWidget);
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      // Check first insight is showing again
      expect(find.text('First Insight'), findsOneWidget);
    });
  });
}

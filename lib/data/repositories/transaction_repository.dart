import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final dbHelper = DatabaseHelper.instance;

  // 1. Add Transaction
  Future<int> addTransaction(TransactionModel transaction) {
    return dbHelper.insertTransaction(transaction.toMap());
  }

  // 2. Fetch All (Clean and Robust Mapping Syntax ✅ Fixed Line 16/17 Error)
  Future<List<TransactionModel>> fetchTransactions() async {
    try {
      // Direct raw data query pull from backend db helper
      final List<Map<String, dynamic>> allData = await dbHelper
          .getAllTransactions();

      // Clean stream conversion mapping loop (Type safe execution architecture)
      return allData.map((map) => TransactionModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint("❌ TransactionRepository Error in fetchTransactions: $e");
      return [];
    }
  }

  // 3. Monthly Total (Loop based - Full Proof)
  Future<double> getMonthlyTotal() async {
    try {
      final transactions = await fetchTransactions();
      final now = DateTime.now();
      double total = 0.0;

      for (var tx in transactions) {
        if (tx.date.month == now.month && tx.date.year == now.year) {
          total += tx.amount;
        }
      }
      return total;
    } catch (e) {
      debugPrint("❌ TransactionRepository Error in getMonthlyTotal: $e");
      return 0.0;
    }
  }

  // 4. Today's Total
  Future<double> getTodayTotal() async {
    try {
      final transactions = await fetchTransactions();
      final now = DateTime.now();
      double total = 0.0;

      for (var tx in transactions) {
        if (tx.date.day == now.day &&
            tx.date.month == now.month &&
            tx.date.year == now.year) {
          total += tx.amount;
        }
      }
      return total;
    } catch (e) {
      debugPrint("❌ TransactionRepository Error in getTodayTotal: $e");
      return 0.0;
    }
  }
}

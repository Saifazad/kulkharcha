import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // --- 1. Thread-Safe Singleton Pattern Setup ---
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Getter for database connection
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kulkharcha.db');

    // Dynamically create merchant_categories table if it doesn't exist (for existing users)
    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS merchant_categories (
        merchant TEXT PRIMARY KEY,
        category TEXT NOT NULL
      )
    ''');

    await _prePopulateCategories(_database!);
    
    // Clear out placeholders/mock locations to keep them null
    await _database!.rawUpdate(
      "UPDATE transactions SET location = NULL WHERE location = 'Patna, Bihar' OR location = 'Mithapur, Patna' OR location = 'Location Disabled' OR location = 'Local'"
    );
    
    return _database!;
  }

  // --- 2. Database Initialization ---
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    debugPrint("📂 Database Path: $path");

    return await openDatabase(
      path,
      version: 2, // Upgraded to version 2 for location tracking support
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  // --- 2b. Database Schema Upgrades ---
  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN location TEXT');
        debugPrint("🚀 Database Upgrade: Added 'location' column to transactions table successfully.");
      } catch (e) {
        debugPrint("⚠️ Database Upgrade Warning: $e");
      }
    }
  }

  // --- 3. Schema Creation (Tables Setup) ---
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const numType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const nullableTextType = 'TEXT';

    // A. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name $textType,
        iconPath $textType,
        colorHex $intType
      )
    ''');

    // B. Transactions Table (Optimized for SMS tracking structure)
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        amount $numType,
        date $textType,
        category $textType,
        description $nullableTextType,
        type $textType,
        is_automatic $intType,
        location TEXT
      )
    ''');

    // C. Merchant Categories Table for Personalization
    await db.execute('''
      CREATE TABLE IF NOT EXISTS merchant_categories (
        merchant TEXT PRIMARY KEY,
        category TEXT NOT NULL
      )
    ''');

    // Pre-populate default items
    await _prePopulateCategories(db);
  }

  // --- 4. Pre-Populate Default Categories ---
  Future<void> _prePopulateCategories(Database db) async {
    final defaultCategories = [
      {
        'id': 'farming',
        'name': 'Kheti/Farming',
        'iconPath': 'assets/icons/farming.svg',
        'colorHex': 0xFF2E7D32,
      },
      {
        'id': 'food',
        'name': 'Food & Groceries',
        'iconPath': 'assets/icons/food.svg',
        'colorHex': 0xFFFF9800,
      },
      {
        'id': 'bills',
        'name': 'Bills & Recharges',
        'iconPath': 'assets/icons/bills.svg',
        'colorHex': 0xFF2196F3,
      },
      {
        'id': 'fuel',
        'name': 'Fuel & Transport',
        'iconPath': 'assets/icons/fuel.svg',
        'colorHex': 0xFFE91E63,
      },
      {
        'id': 'shopping',
        'name': 'Shopping',
        'iconPath': 'assets/icons/shopping.svg',
        'colorHex': 0xFF9C27B0,
      },
      {
        'id': 'medical',
        'name': 'Medical & Health',
        'iconPath': 'assets/icons/medical.svg',
        'colorHex': 0xFFE53935,
      },
      {
        'id': 'atm',
        'name': 'Cash (ATM)',
        'iconPath': 'assets/icons/atm.svg',
        'colorHex': 0xFF009688,
      },
      {
        'id': 'general',
        'name': 'General',
        'iconPath': 'assets/icons/general.svg',
        'colorHex': 0xFF9E9E9E,
      },
    ];

    for (var cat in defaultCategories) {
      await db.insert(
        'categories',
        cat,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    debugPrint("✅ Default 8 categories seeded/updated in database successfully.");
  }

  // ==========================================
  // 🔥 TRANSACTIONS CRUD PIPELINE (Raw Maps)
  // ==========================================

  // --- Insert Transaction with Strict Duplicate Check ---
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;

    // 🚨 DUPLICATE PREVENTION LOGIC FOR AUTOMATIC SMS:
    if (row['is_automatic'] == 1 && row['description'] != null) {
      final List<Map<String, dynamic>> existing = await db.query(
        'transactions',
        where: 'amount = ? AND date = ? AND description = ?',
        whereArgs: [row['amount'], row['date'], row['description']],
      );

      if (existing.isNotEmpty) {
        debugPrint(
          "🛡️ Duplicate Transaction Blocked: ₹${row['amount']} ka SMS pehle se save hai.",
        );
        return -1; // Insertion abort feedback
      }
    }

    return await db.insert(
      'transactions',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Read All Transactions (Clean Architecture Rule: Returns Raw Maps ✅) ---
  // Is change se aapke TransactionRepository ke line 16-17 ka error bilkul khatam ho jayega!
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await instance.database;

    // Direct raw database querying returning List<Map<String, dynamic>>
    return await db.query('transactions', orderBy: 'date DESC, id DESC');
  }

  // --- Read Category-wise Total Expense for Dashboard Cards ---
  Future<Map<String, double>> getCategoryWiseExpenses() async {
    final db = await instance.database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT category, SUM(amount) as total 
      FROM transactions 
      GROUP BY category
    ''');

    Map<String, double> categoryMap = {};
    for (var row in result) {
      if (row['category'] != null) {
        categoryMap[row['category'].toString()] =
            double.tryParse(row['total'].toString()) ?? 0.0;
      }
    }
    return categoryMap;
  }

  // --- Delete Transaction ---
  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Update Transaction Category ---
  Future<int> updateTransactionCategory(int id, String category) async {
    final db = await instance.database;

    // Retrieve raw transaction description to learn the category personalization mapping
    try {
      final List<Map<String, dynamic>> results = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (results.isNotEmpty) {
        final String? description = results.first['description'] as String?;
        if (description != null && description.isNotEmpty) {
          final String? merchant = _extractMerchantNameForPersonalization(description);
          if (merchant != null && merchant.isNotEmpty) {
            await db.insert(
              'merchant_categories',
              {
                'merchant': merchant.toLowerCase().trim(),
                'category': category,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            debugPrint("💾 Learned customized category mapping: '$category' for merchant '$merchant'");
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ Failed to learn custom category mapping: $e");
    }

    return await db.update(
      'transactions',
      {'category': category},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  // --- Extract Merchant/Receiver Name from description ---
  // Specifically designed for Kotak / Indian UPI bank SMS format.
  String? _extractMerchantNameForPersonalization(String description) {
    final text = description.trim();
    if (text.isEmpty) return null;

    // ✅ Pattern 1 (Most Precise): "to [MERCHANT] on DD/MM/YYYY"
    // E.g. "Sent Rs.24.00 from XXXXXX5793 to QAYYUM AHMAD on 20/05/2026."
    // Using lazy .+? to stop at first " on " followed by a date
    final toOnDatePattern = RegExp(
      r'\bto\s+([A-Za-z].+?)\s+on\s+\d{2}/\d{2}/\d{4}',
      caseSensitive: false,
    );
    var match = toOnDatePattern.firstMatch(text);
    if (match != null) {
      return match.group(1)!.trim();
    }

    // ✅ Pattern 2: "paid to [MERCHANT] on DD/MM/YYYY" or "transferred to [MERCHANT] on DD/MM/YYYY"
    final paidToOnPattern = RegExp(
      r'\b(?:paid|transferred)\s+to\s+([A-Za-z].+?)\s+on\s+\d{2}/\d{2}/\d{4}',
      caseSensitive: false,
    );
    match = paidToOnPattern.firstMatch(text);
    if (match != null) {
      return match.group(1)!.trim();
    }

    // ✅ Pattern 3: "to [MERCHANT] UPI ref" (no date in SMS)
    final toUpiRefPattern = RegExp(
      r'\bto\s+([A-Za-z].+?)\s+(?:UPI\s+)?ref\b',
      caseSensitive: false,
    );
    match = toUpiRefPattern.firstMatch(text);
    if (match != null) {
      return match.group(1)!.trim();
    }

    // ✅ Pattern 4: "spent at [MERCHANT]" or "spent on [MERCHANT]"
    // E.g. "Rs 985.00 spent at Pizza Hut."
    final spentAtPattern = RegExp(
      r'\bspent\s+(?:at|on)\s+([A-Za-z].+?)(?:\.|from|on\b|\busing)',
      caseSensitive: false,
    );
    match = spentAtPattern.firstMatch(text);
    if (match != null) {
      return match.group(1)!.trim();
    }

    return null;
  }

  // --- Fetch Customized Category for Transaction if Available ---
  Future<String?> getCustomMerchantCategory(String description) async {
    final String? merchant = _extractMerchantNameForPersonalization(description);
    if (merchant == null || merchant.isEmpty) return null;

    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'merchant_categories',
      where: 'merchant = ?',
      whereArgs: [merchant.toLowerCase().trim()],
    );

    if (maps.isNotEmpty) {
      final String savedCategory = maps.first['category'] as String;
      debugPrint("🎯 Found custom category override: '$savedCategory' for merchant '$merchant'");
      return savedCategory;
    }

    return null;
  }

  // --- Close Database Connection Safely ---
  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

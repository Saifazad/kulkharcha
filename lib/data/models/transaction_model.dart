class TransactionModel {
  final int? id;
  final double amount;
  final DateTime date;
  final String category;
  final String description;
  final String type; // 'SMS' ya 'CASH'
  final int isAutomatic; // 1 for True, 0 for False

  const TransactionModel({
    this.id,
    required this.amount,
    required this.date,
    required this.category,
    required this.description,
    required this.type,
    this.isAutomatic = 0,
  });

  // --- 1. Database (Map) se Model banane ke liye (Crash Proof Setup ✅) ---
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    // Robust Double Casting Rule: Int aur Double dono layouts ko safely handle karne ke liye
    double parsedAmount = 0.0;
    if (map['amount'] != null) {
      parsedAmount = (map['amount'] is int)
          ? (map['amount'] as int).toDouble()
          : double.tryParse(map['amount'].toString()) ?? 0.0;
    }

    // Safe DateTime parsing logic
    DateTime parsedDate = DateTime.now();
    if (map['date'] != null) {
      parsedDate = DateTime.tryParse(map['date'].toString()) ?? DateTime.now();
    }

    return TransactionModel(
      id: map['id'] as int?,
      amount: parsedAmount,
      date: parsedDate,
      category: map['category']?.toString() ?? 'General',
      description: map['description']?.toString() ?? '',
      type: map['type']?.toString() ?? 'CASH',
      isAutomatic: (map['is_automatic'] as int?) ?? 0,
    );
  }

  // --- 2. Model se Database (Map) banane ke liye ---
  Map<String, dynamic> toMap() {
    return {
      if (id != null)
        'id': id, // ID tabhi bhejo jab wo null na ho (Auto-increment friendly)
      'amount': amount,
      'date': date.toIso8601String(), // Store full ISO string including time
      'category': category.trim().isEmpty ? 'General' : category,
      'description': description.trim(),
      'type': type,
      'is_automatic': isAutomatic,
    };
  }

  // --- 3. Immutability aur Modifying ke liye copyWith method ✅ ---
  // Iska use karke aap kisi bhi transaction ka data badal sakte ho bina naya object scratch se banaye
  TransactionModel copyWith({
    int? id,
    double? amount,
    DateTime? date,
    String? category,
    String? description,
    String? type,
    int? isAutomatic,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      type: type ?? this.type,
      isAutomatic: isAutomatic ?? this.isAutomatic,
    );
  }
}

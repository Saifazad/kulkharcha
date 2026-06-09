class CategoryModel {
  final String id;
  final String name;
  final String iconPath; // SVG ya Image path
  final int colorHex; // Category ka premium custom color hex value

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.colorHex,
  });

  // --- 1. Map to Object (Database se nikalne ke liye - Crash Proof Setup ✅) ---
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    // Robust Integer Casting Rule for Colors
    int parsedColor = 0xFF2E7D32; // Default safe backup green color
    if (map['colorHex'] != null) {
      if (map['colorHex'] is int) {
        parsedColor = map['colorHex'] as int;
      } else {
        parsedColor = int.tryParse(map['colorHex'].toString()) ?? 0xFF2E7D32;
      }
    }

    return CategoryModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'General',
      iconPath: map['iconPath']?.toString() ?? 'assets/icons/general.svg',
      colorHex: parsedColor,
    );
  }

  // --- 2. Object to Map (Database mein dalne ke liye) ---
  Map<String, dynamic> toMap() {
    return {
      'id': id.trim(),
      'name': name.trim().isEmpty ? 'General' : name.trim(),
      'iconPath': iconPath.trim(),
      'colorHex': colorHex,
    };
  }

  // --- 3. Senior Dev Rule: State Management aur Modifying ke liye copyWith method ✅ ---
  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconPath,
    int? colorHex,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}

class SMSParser {
  // 1. Amount nikalne ke liye Regex
  // Ye "Rs. 500", "INR 1,200.50", "spent 100" jaise patterns ko dhoondta hai
  static final RegExp amountRegExp = RegExp(
    r'(?:(?:RS|INR|Rs|rs|Inr)\.?\s?)(\d+(?:[.,]\d+)*)',
    caseSensitive: false,
  );

  // 2. Merchant/Title nikalne ke liye common keywords
  // SMS mein "at", "to", "vpa" ke baad aksar merchant ka naam hota hai
  static final RegExp merchantRegExp = RegExp(
    r'(?:at|to|vpa|info)\s+([a-zA-Z0-9\s\.\*\-]+)(?=\s|on|using|link|\.)',
    caseSensitive: false,
  );

  static Map<String, dynamic>? parseSMS(String body) {
    try {
      // Amount nikalna
      final amountMatch = amountRegExp.firstMatch(body);
      if (amountMatch == null) {
        return null; // Agar amount nahi mila toh ignore karo
      }

      String amountStr = amountMatch.group(1)!.replaceAll(',', '');
      double amount = double.parse(amountStr);

      // Merchant nikalna
      final merchantMatch = merchantRegExp.firstMatch(body);
      String merchant = merchantMatch != null
          ? merchantMatch.group(1)!.trim()
          : "Unknown Merchant";

      // Date toh hum system ki current date hi lenge
      return {
        'amount': amount,
        'merchant': merchant,
        'category': _autoDetectCategory(merchant, body),
      };
    } catch (e) {
      print("Parsing Error: $e");
      return null;
    }
  }

  // 3. Simple AI Category Detection
  static String _autoDetectCategory(String merchant, String body) {
    String text = (merchant + body).toLowerCase();

    if (text.contains('zomato') ||
        text.contains('swiggy') ||
        text.contains('restaurant')) {
      return '1'; // Food ID
    } else if (text.contains('amazon') ||
        text.contains('flipkart') ||
        text.contains('myntra')) {
      return '2'; // Shopping ID
    } else if (text.contains('uber') ||
        text.contains('ola') ||
        text.contains('petrol')) {
      return '3'; // Transport ID
    } else if (text.contains('recharge') ||
        text.contains('bill') ||
        text.contains('electricity')) {
      return '4'; // Bills ID
    }

    return '1'; // Default: Food (Ya koi General category)
  }
}

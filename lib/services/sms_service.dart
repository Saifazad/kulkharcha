import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_sms_receiver/easy_sms_receiver.dart' hide SmsMessage;
import '../data/database/database_helper.dart';
import 'location_service.dart';

class SMSService {
  final SmsQuery _query = SmsQuery();
  final EasySmsReceiver _easySms = EasySmsReceiver.instance;

  Future<void> initSMSListener() async {
    print("🚀 KulKharcha SMS Service: Listening...");
    await fetchAndParseSMS();
  }

  // 📡 Real-time listener — jaise hi SMS aaye, turant process ho aur UI update ho
  // [onNewTransaction] callback HomeScreen ko notify karta hai ki refresh kare
  Future<void> startRealtimeListener({required Future<void> Function() onNewTransaction}) async {
    // Permission check
    var status = await Permission.sms.status;
    if (status.isDenied) {
      status = await Permission.sms.request();
    }
    if (!status.isGranted) {
      print("⚠️ SMS permission nahi mili — real-time listener start nahi hoga.");
      return;
    }

    _easySms.listenIncomingSms(
      onNewMessage: (message) async {
        final String body = message.body ?? '';
        print("📩 [Real-time] Naya SMS aaya: '$body'");

        if (body.isNotEmpty && _isBankSMS(body)) {
          print("🏦 [Real-time] Bank SMS detect hua! Processing...");

          final double amount = _extractAmount(body);
          if (amount > 0) {
            final locationService = LocationService();
            final String? locationName = await locationService.getCurrentLocationName();

            // Custom category check karo pehle
            final customCategory = await DatabaseHelper.instance.getCustomMerchantCategory(body);
            final finalCategory = customCategory ?? _autoDetectCategory(body);

            final int result = await DatabaseHelper.instance.insertTransaction({
              'amount': amount,
              'date': DateTime.now().toIso8601String(),
              'description': body,
              'category': finalCategory,
              'type': 'SMS',
              'is_automatic': 1,
              'location': locationName,
            });

            if (result != -1) {
              print("✅ [Real-time] ₹$amount save hua '$finalCategory' category mein! UI update ho raha hai...");
              await onNewTransaction(); // HomeScreen ko notify karo — UI refresh karo!
            } else {
              print("🛡️ [Real-time] Duplicate SMS — skip kiya.");
            }
          }
        }
      },
    );
    print("📡 [Real-time] SMS Listener active hai! Ab koi bhi bank SMS aayega toh turant UI update hoga.");
  }

  Future<void> fetchAndParseSMS({bool isBackground = false}) async {
    var status = await Permission.sms.status;
    print("🔍 [KulkAI Debug] Current SMS Permission Status: $status");

    if (status.isDenied && !isBackground) {
      print("🔍 [KulkAI Debug] Requesting SMS Permission...");
      status = await Permission.sms.request();
      print("🔍 [KulkAI Debug] SMS Permission Request Result: $status");
    }

    if (status.isGranted) {
      String? locationName;
      if (!isBackground) {
        final locationService = LocationService();
        locationName = await locationService.getCurrentLocationName();
      }

      // 50 messages read karna kaafi hai latest transactions ke liye
      print("🔍 [KulkAI Debug] Scanning latest 50 SMS from inbox...");
      final List<SmsMessage> messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 50,
      );
      print(
        "🔍 [KulkAI Debug] Found ${messages.length} messages in SMS inbox.",
      );

      for (var msg in messages) {
        if (msg.body != null && _isBankSMS(msg.body!)) {
          print("🔍 [KulkAI Debug] Detected Bank SMS: '${msg.body}'");
          // Date Formatting (Keep full ISO 8601 to preserve transaction time)
          DateTime smsDate = msg.date ?? DateTime.now();
          String formattedDate = smsDate.toIso8601String();

          // Amount Extraction
          double amount = _extractAmount(msg.body!);

          if (amount > 0) {
            // Check if there is a customized category mapping first!
            final customCategory = await DatabaseHelper.instance.getCustomMerchantCategory(msg.body!);
            final finalCategory = customCategory ?? _autoDetectCategory(msg.body!);

            // DATABASE CALL: Humne yahan database helper ko integrate kar diya hai
            // Duplicate prevention logic 'insertTransaction' ke andar pehle se hai
            await DatabaseHelper.instance.insertTransaction({
              'amount': amount,
              'date': formattedDate,
              'description': msg.body,
              'category': finalCategory,
              'type': 'SMS',
              'is_automatic': 1,
              'location': locationName,
            });

            print("💰 Transaction Processed: ₹$amount with category: $finalCategory");
          } else {
            print("⚠️ SMS detect hua par amount nahi nikal paya.");
          }
        }
      }
    }
  }

  // Keywords filter optimized for Indian Banks
  bool _isBankSMS(String body) {
    final debitKeywords = [
      'debited',
      'spent',
      'sent',
      'paid',
      'dr to',
      'transferred',
      'withdrawn',
      'txn of',
    ];
    String text = body.toLowerCase();

    // If it is a credit alert without any debit terms, ignore it.
    if ((text.contains('credited') ||
            text.contains('received') ||
            text.contains('refunded')) &&
        !debitKeywords.any((key) => text.contains(key))) {
      return false;
    }

    return debitKeywords.any((key) => text.contains(key));
  }

  // Multi-Pattern Regex for robust amount extraction
  double _extractAmount(String body) {
    List<RegExp> patterns = [
      RegExp(r'(?:RS|INR|Rs\.?|Amt)\s?([0-9][0-9,.]*)\b', caseSensitive: false),
      RegExp(
        r'debited\s*(?:by|with|of)?\s*(?:rs\.?|inr)?\s*([0-9][0-9,.]*)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'([0-9][0-9,.]*)\s*(?:rs\.?|inr)?\s*(?:debited|spent|paid)',
        caseSensitive: false,
      ),
      RegExp(r'VPA\s?([0-9][0-9,.]*)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      var match = pattern.firstMatch(body);
      if (match != null) {
        String amountStr = match.group(1)!.replaceAll(',', '');
        double? parsed = double.tryParse(amountStr);
        if (parsed != null) return parsed;
      }
    }
    return 0.0;
  }

  // Category detection for 8 comprehensive categories
  String _autoDetectCategory(String body) {
    String text = body.toLowerCase();

    // 1. Kheti/Farming
    if (text.contains('mandi') ||
        text.contains('kisan') ||
        text.contains('fertilizer') ||
        text.contains('urea') ||
        text.contains('crop')) {
      return 'Kheti/Farming';
    }

    // 2. Food & Groceries
    if (text.contains('zomato') ||
        text.contains('swiggy') ||
        text.contains('starbucks') ||
        text.contains('restaurant') ||
        text.contains('hotel') ||
        text.contains('cafe') ||
        text.contains('food') ||
        text.contains('groceries') ||
        text.contains('mart') ||
        text.contains('dairy') ||
        text.contains('supermarket')) {
      return 'Food & Groceries';
    }

    // 3. Fuel & Transport
    if (text.contains('petrol') ||
        text.contains('diesel') ||
        text.contains('cng') ||
        text.contains('fuel') ||
        text.contains('hpcl') ||
        text.contains('bpcl') ||
        text.contains('iocl') ||
        text.contains('uber') ||
        text.contains('ola') ||
        text.contains('rapido') ||
        text.contains('metro') ||
        text.contains('irctc') ||
        text.contains('train') ||
        text.contains('cab')) {
      return 'Fuel & Transport';
    }

    // 4. Bills & Recharges
    if (text.contains('jio') ||
        text.contains('airtel') ||
        text.contains('vi ') ||
        text.contains('netflix') ||
        text.contains('spotify') ||
        text.contains('youtube premium') ||
        text.contains('recharge') ||
        text.contains('bill') ||
        text.contains('electricity') ||
        text.contains('broadband') ||
        text.contains('dth') ||
        text.contains('rent')) {
      return 'Bills & Recharges';
    }

    // 5. Shopping
    if (text.contains('amazon') ||
        text.contains('flipkart') ||
        text.contains('myntra') ||
        text.contains('meesho') ||
        text.contains('nykaa') ||
        text.contains('zara') ||
        text.contains('hnm') ||
        text.contains('h&m') ||
        text.contains('shopping') ||
        text.contains('clothing') ||
        text.contains('store')) {
      return 'Shopping';
    }

    // 6. Medical & Health
    if (text.contains('pharmacy') ||
        text.contains('apollo') ||
        text.contains('hospital') ||
        text.contains('clinic') ||
        text.contains('medical') ||
        text.contains('medicine') ||
        text.contains('chemist') ||
        text.contains('lab')) {
      return 'Medical & Health';
    }

    // 7. Cash (ATM)
    if (text.contains('atm') ||
        text.contains('cash withdrawal') ||
        text.contains('withdrawn')) {
      return 'Cash (ATM)';
    }

    return 'General';
  }
}

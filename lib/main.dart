import 'package:flutter/material.dart';
import 'app.dart';
import 'services/sms_service.dart';
import 'services/background_fetch.dart'; // Naya service import karein
import 'data/database/database_helper.dart';

void main() async {
  // 1. Flutter engine ko initialize karna sabse pehla kaam hai
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Database ko pehle hi ready kar lena taaki tables ban jayein
    await DatabaseHelper.instance.database;
    print("✅ Database Initialized Successfully");

    // 3. Background Fetch Service ko start karein
    // Ye line aapke app ko background mein "SMS read" karne ki power degi
    final bgService = BackgroundFetchService();
    await bgService.initialize();
    print("✅ Background Fetch Service Initialized");

    // 4. (Optional) Foreground Sync: App khulte hi ek baar sync karna
    // Run asynchronously so that it doesn't block the UI / runApp startup
    final smsService = SMSService();
    smsService.fetchAndParseSMS().then((_) {
      debugPrint("✅ Initial SMS Sync Done");
    }).catchError((e) {
      debugPrint("❌ Initial SMS Sync Error: $e");
    });
  } catch (e) {
    print("❌ Initialization Error: $e");
  }

  // 5. App Launch
  runApp(const KulKharchaApp());
}

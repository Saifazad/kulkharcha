import 'package:workmanager/workmanager.dart';
import 'sms_service.dart';
import '../data/database/database_helper.dart';

class BackgroundFetchService {
  static const String taskName = "com.kulkharcha.sms_sync_task";

  // Ye wo function hai jo background mein execute hoga
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      print("📡 Background Task Started: $task");

      try {
        // 1. Database initialize karein (Background process ke liye zaruri hai)
        await DatabaseHelper.instance.database;

        // 2. SMS Service ko call karein
        final smsService = SMSService();
        await smsService.fetchAndParseSMS(isBackground: true);

        print("✅ Background SMS Sync Complete");
        return Future.value(true);
      } catch (e) {
        print("❌ Background Task Error: $e");
        return Future.value(false);
      }
    });
  }

  // Background task ko register karne ke liye
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Testing ke liye true, Production ke liye false rakhein
    );

    // Har 15-30 minute mein chalne ke liye schedule karein
    await Workmanager().registerPeriodicTask(
      "1",
      taskName,
      frequency: const Duration(
        minutes: 15,
      ), // Minimum 15 mins allowed by Android
      constraints: Constraints(
        networkType: NetworkType.notRequired, // Bina internet ke bhi chale
        requiresBatteryNotLow: true,
      ),
    );
  }
}

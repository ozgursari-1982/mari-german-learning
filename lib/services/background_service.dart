import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'notification_service.dart';

// Unique task name
const String periodicTaskName = "com.mari.learning.periodic_tips";

// Callback dispatcher (must be top-level/static)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("🔄 Background Task Started: $task");

    if (task == periodicTaskName) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final notificationService = NotificationService();
        await notificationService.initialize();

        // 1. Check if notifications are enabled
        final isEnabled = prefs.getBool('notifications_enabled') ?? true;
        if (!isEnabled) {
          print("🔕 Notifications disabled by user.");
          return Future.value(true);
        }

        // 2. Check time range (e.g. 09:00 - 22:00)
        final now = DateTime.now();
        final startHour = prefs.getInt('notification_start_hour') ?? 9;
        final endHour = prefs.getInt('notification_end_hour') ?? 22;

        if (now.hour < startHour || now.hour >= endHour) {
          print(
            "🌙 Quiet hours (Now: ${now.hour}, Allowed: $startHour-$endHour). Skipping.",
          );
          return Future.value(true);
        }

        // 3. Get cached tips
        final tipsJson = prefs.getString('daily_tips_cache');
        if (tipsJson != null) {
          final List<dynamic> decoded = jsonDecode(tipsJson);
          if (decoded.isNotEmpty) {
            // Pick a random tip
            final random = Random();
            final tipData = decoded[random.nextInt(decoded.length)];

            final title = tipData['title'] ?? 'Almanca İpucu';
            final body =
                tipData['content'] ?? 'Almanca öğrenmeye devam et! 🇩🇪';

            await notificationService.showNotification(
              id: random.nextInt(100000),
              title: title,
              body: body,
            );
            print("📢 Notification sent: $title");
          } else {
            print("⚠️ Cached tips list is empty.");
          }
        } else {
          print("⚠️ No cached tips found. Using fallback.");
          // Fallback if no specific tips are generated
          // Optionally we could show a generic message, but better not to spam if no content.
        }
      } catch (e) {
        print("❌ Error in background task: $e");
        return Future.value(false); // Retry?
      }
    }

    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to false in production
    );
    print("✅ Workmanager initialized");
  }

  static Future<void> registerPeriodicTask({int frequencyMinutes = 30}) async {
    // Android requires minimum 15 mins
    final frequency = frequencyMinutes < 15 ? 15 : frequencyMinutes;

    await Workmanager().registerPeriodicTask(
      "periodic-learning-tips",
      periodicTaskName,
      frequency: Duration(minutes: frequency),
      // Constraints
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy
          .replace, // Correct policy for periodic tasks
    );
    print("⏰ Periodic task registered: Every $frequency minutes");
  }

  static Future<void> cancelTasks() async {
    await Workmanager().cancelAll();
    print("🚫 All background tasks cancelled");
  }
}

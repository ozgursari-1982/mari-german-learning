import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:math';
import 'vocabulary_service.dart';

/// Simple foreground notification service for vocabulary reminders
class VocabularyNotificationService {
  static final VocabularyNotificationService _instance =
      VocabularyNotificationService._internal();
  factory VocabularyNotificationService() => _instance;
  VocabularyNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Timer? _timer;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
    _isInitialized = true;
    print('✅ Notification service initialized');
  }

  Future<bool> requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// Start periodic notifications (only while app is open)
  void startPeriodic({
    required String userId,
    int intervalMinutes = 120, // 2 hours
  }) {
    stopPeriodic(); // Cancel existing

    _timer = Timer.periodic(Duration(minutes: intervalMinutes), (timer) async {
      final now = DateTime.now();
      // Only send between 9 AM - 10 PM
      if (now.hour >= 9 && now.hour < 22) {
        await _sendWordNotification(userId);
      }
    });

    print('⏰ Started periodic notifications (every $intervalMinutes min)');
  }

  void stopPeriodic() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _sendWordNotification(String userId) async {
    try {
      final vocabService = VocabularyService(userId);
      final allWords = await vocabService.getAllWords();

      if (allWords.isEmpty) {
        print('⚠️ No words for notification');
        return;
      }

      // Pick due words or random
      final dueWords = allWords
          .where(
            (w) => w.nextReviewAt.isBefore(
              DateTime.now().add(const Duration(days: 1)),
            ),
          )
          .toList();

      final wordList = dueWords.isNotEmpty ? dueWords : allWords;
      final word = wordList[Random().nextInt(wordList.length)];

      await _notifications.show(
        Random().nextInt(100000),
        '🇩🇪 ${word.german}',
        '📝 ${word.translation}\n💭 ${word.exampleSentence}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'vocab_channel',
            'Kelime Hatırlatmaları',
            channelDescription: 'Günlük kelime tekrarı',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
        ),
      );

      print('📢 Notification sent: ${word.german}');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Send test notification immediately
  Future<void> sendTest() async {
    await _notifications.show(
      999,
      '🎯 Test - Kelime Bildirimleri Aktif!',
      'Her 2 saatte bir kelime hatırlatması alacaksınız.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vocab_channel',
          'Kelime Hatırlatmaları',
          importance: Importance.high,
        ),
      ),
    );
  }
}

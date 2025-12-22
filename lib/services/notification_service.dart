import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true, // Critical alerts for iOS
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channels
    await _createNotificationChannels();
  }
  
  static Future<void> _createNotificationChannels() async {
    // High-priority alarm channel
    const alarmChannel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarms',
      description: 'Alarm notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
    );
    
    // Wake-up check channel
    const wakeCheckChannel = AndroidNotificationChannel(
      'wake_check_channel',
      'Wake-up Verification',
      description: 'Verifies you are actually awake',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(wakeCheckChannel);
  }
  
  /// Schedule wake-up verification notification (5 minutes after alarm dismissed)
  static Future<void> scheduleWakeUpCheck(int alarmId) async {
    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 5));
    
    await _notifications.zonedSchedule(
      alarmId + 10000, // Offset ID to avoid collision
      '⏰ Are you still awake?',
      'Tap to confirm you\'re up, or alarm will restart',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'wake_check_channel',
          'Wake-up Verification',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }
  
  /// iOS notification cascade (32 notifications over 16 minutes)
  static Future<void> scheduleIOSAlarmCascade(
    int alarmId,
    DateTime alarmTime,
  ) async {
    // Schedule 32 notifications at 30-second intervals
    for (int i = 0; i < 32; i++) {
      final scheduledTime = tz.TZDateTime.from(
        alarmTime.add(Duration(seconds: 30 * i)),
        tz.local,
      );
      
      await _notifications.zonedSchedule(
        alarmId * 100 + i, // Unique ID for each notification
        '⏰ WAKE UP!',
        'Complete mission to dismiss',
        scheduledTime,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            sound: 'alarm_sound.wav',
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
  
  /// Cancel all notifications for an alarm
  static Future<void> cancelAlarmNotifications(int alarmId) async {
    // Cancel main notification
    await _notifications.cancel(alarmId);
    
    // Cancel wake-up check
    await _notifications.cancel(alarmId + 10000);
    
    // Cancel iOS cascade (32 notifications)
    for (int i = 0; i < 32; i++) {
      await _notifications.cancel(alarmId * 100 + i);
    }
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to app
  }
}

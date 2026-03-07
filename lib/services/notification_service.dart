import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Stable notification ID reserved for the bedtime reminder.
  static const int _bedtimeReminderId = 9000;
  
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

    // Bedtime reminder channel
    const bedtimeChannel = AndroidNotificationChannel(
      'bedtime_channel',
      'Bedtime Reminder',
      description: 'Reminds you to go to sleep and start sleep tracking',
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(bedtimeChannel);
  }

  /// Schedule a daily bedtime reminder notification at [bedtime].
  ///
  /// The notification payload [_bedtimePayload] is used to navigate to the
  /// sleep-tracking screen when the user taps it.
  static const String _bedtimePayload = 'bedtime_reminder';

  static Future<void> scheduleBedtimeReminder(TimeOfDay bedtime) async {
    await cancelBedtimeReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      bedtime.hour,
      bedtime.minute,
    );

    // If the time has already passed today, schedule for tomorrow.
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _bedtimeReminderId,
      '🌙 Time for bed!',
      'Tap to start automatic sleep tracking',
      scheduled,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'bedtime_channel',
          'Bedtime Reminder',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      payload: _bedtimePayload,
    );
  }

  /// Cancel any pending bedtime reminder notification.
  static Future<void> cancelBedtimeReminder() async {
    await _notifications.cancel(_bedtimeReminderId);
  }
  
  /// Schedule wake-up verification notification (5 minutes after alarm dismissed)
  static Future<void> scheduleWakeUpCheck(int alarmId) async {
    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 5));
    
    await _notifications.zonedSchedule(
      alarmId + 10000, // Offset ID to avoid collision
      '⏰ Are you still awake?',
      'Tap to confirm you\'re up, or alarm will restart',
      scheduledTime,
      const NotificationDetails(
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
    
    // Cancel snooze notification
    await _notifications.cancel(alarmId + 20000);
    
    // Cancel iOS cascade (32 notifications)
    for (int i = 0; i < 32; i++) {
      await _notifications.cancel(alarmId * 100 + i);
    }
  }
  
  /// Schedule a snooze notification
  static Future<void> scheduleSnooze(
    int alarmId,
    DateTime snoozeTime,
    String missionType,
    int difficulty,
  ) async {
    final scheduledTime = tz.TZDateTime.from(snoozeTime, tz.local);
    
    await _notifications.zonedSchedule(
      alarmId + 20000, // Offset ID for snooze
      '⏰ Snooze Time Up!',
      'Complete your mission to wake up',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarms',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          ongoing: true,
          autoCancel: false,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '$alarmId|$missionType|$difficulty',
    );
  }
  
  static void Function()? _bedtimeTapCallback;

  /// Register a callback that fires when the bedtime reminder notification
  /// is tapped.  Use this to navigate to the sleep-tracking screen.
  static void setBedtimeTapCallback(void Function() cb) {
    _bedtimeTapCallback = cb;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Bedtime reminder tap → delegate to registered callback.
    if (response.payload == _bedtimePayload) {
      _bedtimeTapCallback?.call();
      return;
    }
    // Other notifications: payload contains alarmId|missionType|difficulty.
  }
}

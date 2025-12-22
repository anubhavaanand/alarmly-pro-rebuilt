import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import '../models/alarm.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.wakemeup.alarm');
  static Isar? _isar;
  
  static Future<void> initialize(Isar isar) async {
    _isar = isar;
    
    // Set up method call handler for native → Flutter communication
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  /// Schedule an alarm using native Android AlarmManager
  static Future<void> scheduleAlarm(Alarm alarm) async {
    if (_isar == null) throw Exception('AlarmService not initialized');
    
    try {
      // Save to database first
      await _isar!.writeTxn(() async {
        await _isar!.alarms.put(alarm);
      });
      
      // Schedule via native code
      await _channel.invokeMethod('scheduleAlarm', {
        'alarmId': alarm.id,
        'triggerTime': alarm.time.millisecondsSinceEpoch,
        'missionType': alarm.missionType.name,
        'difficulty': alarm.missionDifficulty,
      });
      
      print('✅ Alarm ${alarm.id} scheduled for ${alarm.timeString}');
    } catch (e) {
      print('❌ Error scheduling alarm: $e');
      rethrow;
    }
  }
  
  /// Cancel an alarm
  static Future<void> cancelAlarm(int alarmId) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {'alarmId': alarmId});
      print('🔕 Alarm $alarmId cancelled');
    } catch (e) {
      print('❌ Error cancelling alarm: $e');
    }
  }
  
  /// Update alarm enabled state
  static Future<void> toggleAlarm(Alarm alarm) async {
    alarm.isEnabled = !alarm.isEnabled;
    
    if (alarm.isEnabled) {
      await scheduleAlarm(alarm);
    } else {
      await cancelAlarm(alarm.id);
      
      // Update in database
      await _isar!.writeTxn(() async {
        await _isar!.alarms.put(alarm);
      });
    }
  }
  
  /// Delete an alarm completely
  static Future<void> deleteAlarm(Alarm alarm) async {
    await cancelAlarm(alarm.id);
    
    await _isar!.writeTxn(() async {
      await _isar!.alarms.delete(alarm.id);
    });
  }
  
  /// Reschedule all active alarms (called after boot)
  static Future<void> rescheduleAllAlarms() async {
    if (_isar == null) return;
    
    final alarms = await _isar!.alarms
        .filter()
        .isEnabledEqualTo(true)
        .findAll();
    
    print('🔄 Rescheduling ${alarms.length} active alarms...');
    
    for (final alarm in alarms) {
      await scheduleAlarm(alarm);
    }
  }
  
  /// Stop currently ringing alarm
  static Future<void> stopAlarm() async {
    try {
      await _channel.invokeMethod('stopAlarm');
    } catch (e) {
      print('❌ Error stopping alarm: $e');
    }
  }
  
  /// Handle method calls from native code
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'rescheduleAlarms':
        await rescheduleAllAlarms();
        break;
        
      case 'alarmTriggered':
        final alarmId = call.arguments['alarmId'] as int;
        print('🔔 Alarm $alarmId triggered from native');
        // Update last triggered time
        final alarm = await _isar!.alarms.get(alarmId);
        if (alarm != null) {
          alarm.lastTriggered = DateTime.now();
          await _isar!.writeTxn(() async {
            await _isar!.alarms.put(alarm);
          });
        }
        break;
        
      default:
        print('Unknown method call: ${call.method}');
    }
  }
  
  /// Calculate next alarm time (considering repeat days)
  static DateTime calculateNextAlarmTime(Alarm alarm) {
    final now = DateTime.now();
    var alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );
    
    // If alarm time has passed today, move to tomorrow
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }
    
    // If no repeat days, return the calculated time
    if (alarm.repeatDays.isEmpty) {
      return alarmTime;
    }
    
    // Find next matching day
    for (int i = 0; i < 7; i++) {
      final weekday = alarmTime.weekday - 1; // Convert to 0-6 (Mon-Sun)
      if (alarm.repeatDays.contains(weekday)) {
        return alarmTime;
      }
      alarmTime = alarmTime.add(const Duration(days: 1));
    }
    
    return alarmTime;
  }
}

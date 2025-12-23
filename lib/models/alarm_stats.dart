import 'package:isar/isar.dart';

part 'alarm_stats.g.dart';

/// Track alarm usage statistics - PREMIUM FEATURE (FREE!)
@Collection()
class AlarmStats {
  Id id = Isar.autoIncrement;
  
  late DateTime date;
  late int alarmId;
  late DateTime scheduledTime;
  late DateTime? actualWakeTime;
  late int snoozeCount;
  late int missionAttempts;
  late int missionSuccessTime; // seconds to complete mission
  late bool dismissed;
  late String missionType;
  late String? notes;
  
  AlarmStats();
  
  factory AlarmStats.create({
    required int alarmId,
    required DateTime scheduledTime,
  }) {
    return AlarmStats()
      ..date = DateTime.now()
      ..alarmId = alarmId
      ..scheduledTime = scheduledTime
      ..actualWakeTime = null
      ..snoozeCount = 0
      ..missionAttempts = 0
      ..missionSuccessTime = 0
      ..dismissed = false
      ..missionType = ''
      ..notes = null;
  }
  
  @ignore
  int get wakeDelay {
    if (actualWakeTime == null) return 0;
    return actualWakeTime!.difference(scheduledTime).inMinutes;
  }
}

/// Weekly/Monthly aggregated stats
@Collection()
class AggregatedStats {
  Id id = Isar.autoIncrement;
  
  late DateTime weekStartDate;
  late int totalAlarms;
  late int missedAlarms;
  late int snoozedAlarms;
  late double avgWakeDelay; // minutes
  late double avgMissionTime; // seconds
  late int bestStreak; // consecutive successful wakes
  late int currentStreak;
  late String missionTypeUsageJson; // JSON encoded map
  
  AggregatedStats();
  
  factory AggregatedStats.forWeek(DateTime weekStart) {
    return AggregatedStats()
      ..weekStartDate = weekStart
      ..totalAlarms = 0
      ..missedAlarms = 0
      ..snoozedAlarms = 0
      ..avgWakeDelay = 0
      ..avgMissionTime = 0
      ..bestStreak = 0
      ..currentStreak = 0
      ..missionTypeUsageJson = '{}';
  }
  
  @ignore
  double get successRate {
    if (totalAlarms == 0) return 0;
    return ((totalAlarms - missedAlarms) / totalAlarms) * 100;
  }
  
  @ignore
  String get successRateString => '${successRate.toStringAsFixed(1)}%';
}

/// Motivational quotes - FREE!
class MotivationalQuotes {
  static const List<String> quotes = [
    "The early bird catches the worm. 🐦",
    "Every morning brings new potential. ☀️",
    "Rise and grind! 💪",
    "Today is a new opportunity. 🌟",
    "Your future self will thank you. ⏰",
    "Discipline beats motivation. 🔥",
    "Small steps lead to big changes. 👣",
    "Make today count! 📈",
    "You're stronger than your snooze button. 💪",
    "Success starts with waking up. 🚀",
    "Embrace the morning, own the day. 🌅",
    "Champions wake up early. 🏆",
    "The world awaits. Get up! 🌍",
    "Your dreams won't work unless you do. 💭",
    "Rise up, start fresh, see the bright opportunity. ✨",
    "Every sunrise is a second chance. 🌄",
    "Be stronger than your excuses. 💯",
    "Wake up with determination, go to bed with satisfaction. 🎯",
    "The secret of getting ahead is getting started. 🏃",
    "Today's actions become tomorrow's habits. 🔄",
  ];
  
  static String getRandomQuote() {
    final random = DateTime.now().millisecondsSinceEpoch % quotes.length;
    return quotes[random];
  }
  
  static String getQuoteOfTheDay() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return quotes[dayOfYear % quotes.length];
  }
}

/// Nap presets - PREMIUM (FREE!)
class NapPresets {
  static const Map<String, int> presets = {
    'Power Nap': 20,
    'Short Rest': 30,
    'Deep Rest': 45,
    'Full Cycle': 90,
    'Extended Rest': 120,
  };
  
  static String getDescription(String name) {
    switch (name) {
      case 'Power Nap':
        return 'Quick energy boost without deep sleep';
      case 'Short Rest':
        return 'Light sleep for refreshment';
      case 'Deep Rest':
        return 'Includes some deep sleep phases';
      case 'Full Cycle':
        return 'Complete sleep cycle with REM';
      case 'Extended Rest':
        return 'Two full sleep cycles';
      default:
        return '';
    }
  }
}

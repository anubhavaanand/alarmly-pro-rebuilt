import 'package:isar/isar.dart';

part 'alarm.g.dart';

@Collection()
class Alarm {
  Id id = Isar.autoIncrement;
  
  late DateTime time;
  late bool isEnabled;
  late List<int> repeatDays; // 0=Mon, 1=Tue, ..., 6=Sun (empty = one-time)
  
  @Enumerated(EnumType.name)
  late MissionType missionType;
  
  late int missionDifficulty; // 1-5
  late bool wakeUpCheckEnabled;
  late String soundPath;
  late double volume; // 0.0 - 1.0
  late bool vibrate;
  late String label;
  
  // Mission-specific data
  late String? missionData; // JSON string for mission-specific config
  
  // Metadata
  late DateTime createdAt;
  late DateTime? lastTriggered;
  late int skipCount; // Track how many times user skipped
  
  // ============ PREMIUM FEATURES (ALL FREE!) ============
  
  // Smart Alarm - wake during light sleep within window
  late bool smartAlarmEnabled;
  late int smartAlarmWindowMinutes; // e.g., 30 = wake up to 30 min early during light sleep
  
  // Gentle Wake - gradual volume increase
  late bool gentleWakeEnabled;
  late int gentleWakeDurationSeconds; // How long to gradually increase volume
  
  // Challenge Mode - multiple missions required
  late bool challengeModeEnabled;
  late List<String> challengeMissions; // List of mission types for challenge
  
  // Nap Mode
  late bool isNapAlarm;
  late int napDurationMinutes; // 0 = regular alarm, >0 = nap alarm
  
  // Snooze Settings
  late int snoozeDurationMinutes;
  late int maxSnoozeCount;
  late int currentSnoozeCount;
  
  // Anti-Dismiss Features
  late bool mathBeforeSnooze; // Require simple math to snooze
  late bool noPhoneFlip; // Disable flip-to-snooze
  late bool captchaRequired; // CAPTCHA before dismiss
  
  // Pre-Alarm
  late bool preAlarmEnabled;
  late int preAlarmMinutes; // Gentle notification X min before alarm
  
  // Weather-based wake
  late bool weatherAnnouncementEnabled;
  
  // Motivational Quote
  late bool showMotivationalQuote;
  
  // Spotify/Music Integration
  late String? spotifyPlaylistUri;
  late bool fadeInMusic;
  
  Alarm();
  
  // Default alarm factory
  factory Alarm.create({
    required DateTime time,
    String label = 'Alarm',
    MissionType missionType = MissionType.math,
    int missionDifficulty = 3,
  }) {
    return Alarm()
      ..time = time
      ..isEnabled = true
      ..repeatDays = []
      ..missionType = missionType
      ..missionDifficulty = missionDifficulty
      ..wakeUpCheckEnabled = true
      ..soundPath = 'default'
      ..volume = 1.0
      ..vibrate = true
      ..label = label
      ..missionData = null
      ..createdAt = DateTime.now()
      ..lastTriggered = null
      ..skipCount = 0
      // Premium features - ALL FREE!
      ..smartAlarmEnabled = false
      ..smartAlarmWindowMinutes = 30
      ..gentleWakeEnabled = true
      ..gentleWakeDurationSeconds = 60
      ..challengeModeEnabled = false
      ..challengeMissions = []
      ..isNapAlarm = false
      ..napDurationMinutes = 0
      ..snoozeDurationMinutes = 5
      ..maxSnoozeCount = 3
      ..currentSnoozeCount = 0
      ..mathBeforeSnooze = false
      ..noPhoneFlip = false
      ..captchaRequired = false
      ..preAlarmEnabled = false
      ..preAlarmMinutes = 5
      ..weatherAnnouncementEnabled = false
      ..showMotivationalQuote = true
      ..spotifyPlaylistUri = null
      ..fadeInMusic = true;
  }
  
  // Create a nap alarm
  factory Alarm.createNap({
    required int durationMinutes,
    MissionType missionType = MissionType.shake,
  }) {
    final now = DateTime.now();
    return Alarm()
      ..time = now.add(Duration(minutes: durationMinutes))
      ..isEnabled = true
      ..repeatDays = []
      ..missionType = missionType
      ..missionDifficulty = 1
      ..wakeUpCheckEnabled = false
      ..soundPath = 'gentle'
      ..volume = 0.7
      ..vibrate = true
      ..label = 'Nap Alarm'
      ..missionData = null
      ..createdAt = DateTime.now()
      ..lastTriggered = null
      ..skipCount = 0
      ..smartAlarmEnabled = false
      ..smartAlarmWindowMinutes = 5
      ..gentleWakeEnabled = true
      ..gentleWakeDurationSeconds = 30
      ..challengeModeEnabled = false
      ..challengeMissions = []
      ..isNapAlarm = true
      ..napDurationMinutes = durationMinutes
      ..snoozeDurationMinutes = 2
      ..maxSnoozeCount = 1
      ..currentSnoozeCount = 0
      ..mathBeforeSnooze = false
      ..noPhoneFlip = false
      ..captchaRequired = false
      ..preAlarmEnabled = false
      ..preAlarmMinutes = 0
      ..weatherAnnouncementEnabled = false
      ..showMotivationalQuote = false
      ..spotifyPlaylistUri = null
      ..fadeInMusic = true;
  }
  
  String get timeString {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  String get repeatDaysString {
    if (repeatDays.isEmpty) return 'One-time';
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 && !repeatDays.contains(5) && !repeatDays.contains(6)) {
      return 'Weekdays';
    }
    
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return repeatDays.map((d) => dayNames[d]).join(', ');
  }
}

enum MissionType {
  math,
  shake,
  squat,
  barcode,
  photo,
  typing,
  walking,
  memory,
}

extension MissionTypeExtension on MissionType {
  String get displayName {
    switch (this) {
      case MissionType.math:
        return 'Math Problem';
      case MissionType.shake:
        return 'Shake Phone';
      case MissionType.squat:
        return 'Do Squats';
      case MissionType.barcode:
        return 'Scan Barcode';
      case MissionType.photo:
        return 'Take Photo';
      case MissionType.typing:
        return 'Type Text';
      case MissionType.walking:
        return 'Walk Steps';
      case MissionType.memory:
        return 'Memory Game';
    }
  }
  
  String get icon {
    switch (this) {
      case MissionType.math:
        return '🔢';
      case MissionType.shake:
        return '📳';
      case MissionType.squat:
        return '🏋️';
      case MissionType.barcode:
        return '📷';
      case MissionType.photo:
        return '📸';
      case MissionType.typing:
        return '⌨️';
      case MissionType.walking:
        return '🚶';
      case MissionType.memory:
        return '🧠';
    }
  }
  
  String get description {
    switch (this) {
      case MissionType.math:
        return 'Solve math problems to dismiss alarm';
      case MissionType.shake:
        return 'Shake your phone vigorously';
      case MissionType.squat:
        return 'Do squats with camera detection';
      case MissionType.barcode:
        return 'Scan a preset barcode';
      case MissionType.photo:
        return 'Take a photo at a specific location';
      case MissionType.typing:
        return 'Type a random sentence correctly';
      case MissionType.walking:
        return 'Walk a certain number of steps';
      case MissionType.memory:
        return 'Complete a memory matching game';
    }
  }
}

import 'package:isar/isar.dart';

part 'sleep_record.g.dart';

@Collection()
class SleepRecord {
  Id id = Isar.autoIncrement;
  
  late DateTime bedTime;
  late DateTime wakeTime;
  late int sleepQuality; // 0-100 score
  late int deepSleepMinutes;
  late int lightSleepMinutes;
  late int remSleepMinutes;
  late int awakeMinutes;
  late List<double> movementData; // Movement intensity per 10-min interval
  late String? notes;
  late bool smartAlarmUsed;
  
  SleepRecord();
  
  factory SleepRecord.create({
    required DateTime bedTime,
    required DateTime wakeTime,
    int sleepQuality = 0,
    int deepSleepMinutes = 0,
    int lightSleepMinutes = 0,
    int remSleepMinutes = 0,
    int awakeMinutes = 0,
    List<double>? movementData,
    String? notes,
    bool smartAlarmUsed = false,
  }) {
    return SleepRecord()
      ..bedTime = bedTime
      ..wakeTime = wakeTime
      ..sleepQuality = sleepQuality
      ..deepSleepMinutes = deepSleepMinutes
      ..lightSleepMinutes = lightSleepMinutes
      ..remSleepMinutes = remSleepMinutes
      ..awakeMinutes = awakeMinutes
      ..movementData = movementData ?? []
      ..notes = notes
      ..smartAlarmUsed = smartAlarmUsed;
  }
  
  /// Total sleep duration in minutes
  @ignore
  int get totalSleepMinutes {
    return wakeTime.difference(bedTime).inMinutes - awakeMinutes;
  }
  
  /// Total time in bed
  @ignore
  Duration get timeInBed => wakeTime.difference(bedTime);
  
  /// Formatted sleep duration
  @ignore
  String get sleepDurationString {
    final hours = totalSleepMinutes ~/ 60;
    final minutes = totalSleepMinutes % 60;
    return '${hours}h ${minutes}m';
  }
  
  /// Sleep efficiency percentage
  @ignore
  double get sleepEfficiency {
    final timeInBedMinutes = timeInBed.inMinutes;
    if (timeInBedMinutes == 0) return 0;
    return (totalSleepMinutes / timeInBedMinutes) * 100;
  }
  
  /// Quality rating as text
  @ignore
  String get qualityRating {
    if (sleepQuality >= 80) return 'Excellent';
    if (sleepQuality >= 60) return 'Good';
    if (sleepQuality >= 40) return 'Fair';
    if (sleepQuality >= 20) return 'Poor';
    return 'Very Poor';
  }
  
  /// Quality color
  @ignore
  int get qualityColor {
    if (sleepQuality >= 80) return 0xFF00FF88;
    if (sleepQuality >= 60) return 0xFF00F5FF;
    if (sleepQuality >= 40) return 0xFFFFD700;
    if (sleepQuality >= 20) return 0xFFFF9500;
    return 0xFFFF3366;
  }
}

/// Sleep cycle phases
enum SleepPhase {
  awake,
  light,
  deep,
  rem,
}

extension SleepPhaseExtension on SleepPhase {
  String get displayName {
    switch (this) {
      case SleepPhase.awake:
        return 'Awake';
      case SleepPhase.light:
        return 'Light Sleep';
      case SleepPhase.deep:
        return 'Deep Sleep';
      case SleepPhase.rem:
        return 'REM Sleep';
    }
  }
  
  int get color {
    switch (this) {
      case SleepPhase.awake:
        return 0xFFFF3366;
      case SleepPhase.light:
        return 0xFF00F5FF;
      case SleepPhase.deep:
        return 0xFF6366F1;
      case SleepPhase.rem:
        return 0xFFFF00FF;
    }
  }
}

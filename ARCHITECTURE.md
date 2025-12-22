# 🏗️ Project Architecture - Wake Me Up Pro

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter (Dart) Layer                     │
├─────────────────────────────────────────────────────────────┤
│  UI Screens          │  Services         │  Missions         │
│  ├─ HomeScreen       │  ├─ AlarmService  │  ├─ MathMission   │
│  ├─ AlarmEditScreen  │  └─ NotifService  │  ├─ ShakeMission  │
│  └─ AlarmRingScreen  │                   │  └─ ...           │
├─────────────────────────────────────────────────────────────┤
│                      MethodChannel Bridge                    │
├─────────────────────────────────────────────────────────────┤
│                    Native Android (Kotlin)                   │
├─────────────────────────────────────────────────────────────┤
│  AlarmScheduler → AlarmManager (System Service)             │
│  AlarmReceiver → Triggered at alarm time                    │
│  AlarmService → Foreground service (plays sound)            │
│  BootReceiver → Reschedule after reboot                     │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Creating an Alarm
```
User Input (AlarmEditScreen)
    ↓
Save to Isar Database
    ↓
AlarmService.scheduleAlarm()
    ↓
MethodChannel → Native Android
    ↓
AlarmScheduler.scheduleAlarm()
    ↓
AlarmManager.setAlarmClock() ← OS System Service
```

### 2. Alarm Triggers
```
AlarmManager fires at scheduled time
    ↓
AlarmReceiver.onReceive()
    ↓
Start AlarmService (foreground) → Plays sound
    ↓
Launch AlarmRingActivity → Full-screen
    ↓
Open Flutter app → AlarmRingScreen
    ↓
Show Mission Screen
    ↓
Mission Complete → Stop AlarmService
    ↓
Schedule Wake-up Verification (5 min later)
```

### 3. Device Reboot
```
Device boots
    ↓
BootReceiver.onReceive()
    ↓
Launch Flutter app
    ↓
MethodChannel → "rescheduleAlarms"
    ↓
Query Isar for all enabled alarms
    ↓
Reschedule each via AlarmScheduler
```

## File Responsibility Matrix

### Flutter Layer (`lib/`)

| File | Responsibility | Lines | Complexity |
|------|---------------|-------|------------|
| `main.dart` | App initialization, theme, routing | ~150 | ⭐⭐ |
| `models/alarm.dart` | Isar database schema | ~200 | ⭐⭐⭐ |
| `services/alarm_service.dart` | Flutter-Native bridge for alarms | ~180 | ⭐⭐⭐⭐ |
| `services/notification_service.dart` | iOS notification cascade | ~150 | ⭐⭐⭐ |
| `screens/home_screen.dart` | Alarm list with reactive updates | ~250 | ⭐⭐⭐ |
| `screens/alarm_edit_screen.dart` | Alarm configuration UI | ~300 | ⭐⭐⭐ |
| `screens/alarm_ring_screen.dart` | Mission launcher | ~180 | ⭐⭐⭐ |
| `missions/math_mission.dart` | Math problem mission | ~250 | ⭐⭐⭐ |
| `missions/shake_mission.dart` | Shake detection mission | ~200 | ⭐⭐⭐⭐ |

### Android Layer (`android/app/src/main/kotlin/`)

| File | Responsibility | Lines | Complexity |
|------|---------------|-------|------------|
| `MainActivity.kt` | MethodChannel handler | ~60 | ⭐⭐ |
| `AlarmReceiver.kt` | Alarm trigger entry point | ~80 | ⭐⭐⭐ |
| `AlarmScheduler.kt` | AlarmManager wrapper | ~100 | ⭐⭐⭐⭐⭐ |
| `AlarmService.kt` | Foreground service (unkillable) | ~200 | ⭐⭐⭐⭐⭐ |
| `BootReceiver.kt` | Post-reboot rescheduling | ~50 | ⭐⭐ |
| `AlarmRingActivity.kt` | Full-screen alarm overlay | ~40 | ⭐⭐ |

## Critical Components Explained

### 🔥 AlarmService (Most Important!)

**Purpose**: Ensures alarm keeps ringing even if:
- App is force-closed
- Device is in Doze mode
- System tries to kill background processes

**How it works**:
1. Runs as **Foreground Service** (high priority, shown in notification bar)
2. Acquires **WakeLock** (prevents CPU from sleeping)
3. Sets volume to **maximum** (prevents silent dismissal)
4. Plays alarm sound in **infinite loop**
5. Returns `START_STICKY` (system recreates if killed)

**Key Code**:
```kotlin
// Runs in foreground (prevents killing)
startForeground(NOTIFICATION_ID, notification)

// Keeps CPU awake
wakeLock = powerManager.newWakeLock(
    PowerManager.PARTIAL_WAKE_LOCK,
    "WakeMeUp::AlarmWakeLock"
)

// Infinite audio loop
mediaPlayer.isLooping = true
mediaPlayer.start()
```

### 🎯 AlarmScheduler

**Purpose**: Schedule alarms that survive Doze mode

**Critical Method**: `setAlarmClock()`
- **Only** method that wakes device from deep Doze
- Shows in lock screen as "Alarm"
- Highest priority alarm type

**Alternative Methods** (don't use!):
- ❌ `setExact()` - Throttled in Doze
- ❌ `setExactAndAllowWhileIdle()` - Max 1 per 9 minutes
- ❌ `set()` - Inaccurate timing

### 📱 MethodChannel Bridge

**Purpose**: Communication between Flutter (Dart) and Android (Kotlin)

**Channel**: `com.wakemeup.alarm`

**Methods**:
```
Flutter → Android:
  - scheduleAlarm(alarmId, triggerTime, missionType, difficulty)
  - cancelAlarm(alarmId)
  - stopAlarm()

Android → Flutter:
  - rescheduleAlarms()
  - alarmTriggered(alarmId)
```

### 💾 Isar Database

**Purpose**: Store alarm configurations locally

**Advantages**:
- Fastest NoSQL database for Flutter
- Synchronous access (no async complications)
- Reactive queries (auto-updates UI)
- Strongly typed

**Schema**:
```dart
@Collection()
class Alarm {
  Id id;
  DateTime time;
  bool isEnabled;
  List<int> repeatDays;
  MissionType missionType;
  int missionDifficulty;
  bool wakeUpCheckEnabled;
  // ... more fields
}
```

## Mission System Architecture

### Mission Interface (Pattern)

All missions follow this pattern:

```dart
class XyzMission extends StatefulWidget {
  final int difficulty;        // 1-5 difficulty level
  final VoidCallback onComplete;  // Called when mission succeeds
  
  @override
  Widget build(BuildContext context) {
    // Mission UI and logic
    // When complete, call: widget.onComplete();
  }
}
```

### Mission Types

| Mission | Input | Difficulty Scaling | Completion Criteria |
|---------|-------|-------------------|---------------------|
| Math | Keyboard | Problem complexity | Correct answer |
| Shake | Accelerometer | Shake count (20-100) | Target shakes reached |
| Squat | Camera + ML Kit | Squat count (10-50) | Detected squats |
| Barcode | Camera | Barcode uniqueness | Correct code scanned |

## Anti-Sabotage Mechanisms

### 1. Wake-Up Verification
After alarm dismissal, schedule notification 5 minutes later:
- If user responds → Confirmed awake
- If no response → Restart alarm at MAX volume

### 2. Volume Lock
During alarm:
- Monitor volume changes via `ContentObserver`
- Reset to maximum if user tries to decrease

### 3. Reboot Persistence
`BootReceiver` ensures:
- All enabled alarms are restored
- Scheduling survives device restart

## Performance Considerations

### Why Isar over SQLite?
- **10x faster** queries
- **Synchronous** access (no await)
- **Smaller** storage footprint
- **Reactive** streams (auto-updates UI)

### Why Foreground Service?
- **Cannot be killed** by system
- User sees ongoing notification
- High priority vs background services

### Why setAlarmClock()?
- **Only method** that bypasses Doze
- System guarantees execution
- Shows in lock-screen clock

## Testing Strategy

### Unit Tests (TODO)
- Alarm time calculation
- Repeat days logic
- Difficulty scaling formulas

### Integration Tests (TODO)
- Database CRUD operations
- MethodChannel communication
- Mission completion flows

### Manual Tests (Critical!)
1. **Doze Mode**: Airplane mode + locked device
2. **Force Kill**: Stop app from Settings
3. **Reboot**: Device restart
4. **Low Battery**: <15% battery (aggressive Doze)

## Future Enhancements

### Planned Features
- [ ] Gradual volume increase (gentle → loud)
- [ ] Smart snooze (requires mini-mission)
- [ ] Sleep statistics & analytics
- [ ] Multiple alarm sounds
- [ ] Backup/restore settings

### Advanced Missions
- [ ] GPS Walking (walk X meters)
- [ ] Memory Game (match cards)
- [ ] Typing Challenge (type sentence)
- [ ] Photo Matching (take photo at location)

## Security & Privacy

### Permissions Used
| Permission | Purpose | Privacy Impact |
|------------|---------|----------------|
| SCHEDULE_EXACT_ALARM | Schedule alarms | Low |
| CAMERA | Missions (squat, barcode) | Medium (local only) |
| WAKE_LOCK | Keep device awake | None |
| VIBRATE | Alarm vibration | None |

**Data Privacy**:
- ✅ All data stored locally (Isar)
- ✅ No network requests
- ✅ No analytics/tracking
- ✅ No cloud sync

---

**This architecture ensures the alarm is truly "unkillable" through multiple layers of redundancy and system-level integration.** 🚀

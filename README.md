# 🚀 Wake Me Up Pro - Unkillable Alarm Clock

An **impossible-to-kill** alarm clock app with interactive wake-up missions. Built with Flutter and native Android/iOS integration to ensure alarms **ALWAYS** ring, even in Doze mode or when the app is terminated.

## 🎯 Key Features

### Core Functionality
- ✅ **Unkillable Alarms** - Uses `setAlarmClock()` on Android (survives Doze mode)
- ✅ **Wake-Up Missions** - Interactive tasks to prove you're awake:
  - 🔢 Math Problems (difficulty scaling)
  - 📳 Shake Phone (accelerometer-based)
  - 🏋️ Squats (ML Kit pose detection)
  - 📷 Barcode Scanner
  - And more...
- ✅ **Wake-Up Verification** - Checks if you're still awake 5 minutes after dismissal
- ✅ **Persistent Across Reboots** - Automatically reschedules alarms after device restart
- ✅ **Foreground Service** - Alarm keeps ringing even when app is killed
- ✅ **Volume Lock** - Prevents volume adjustment during alarm
- ✅ **Full-Screen Override** - Shows alarm even on lock screen

### Technical Highlights
- **Database**: Isar (fastest NoSQL for Flutter)
- **Native Integration**: Android AlarmManager + iOS Critical Alerts
- **ML Kit**: Google ML Kit for pose detection
- **Sensors**: Accelerometer, gyroscope, camera access
- **Beautiful UI**: Material 3 dark theme with glassmorphism

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (3.16+)
   ```bash
   # Check Flutter installation
   flutter doctor
   ```

2. **Android Studio** or **VS Code** with Flutter extensions

3. **Java/Kotlin** (comes with Android Studio)

4. **Git**

## 🛠️ Installation & Setup

### Step 1: Install Flutter

If you don't have Flutter installed:

```bash
# Download Flutter
cd ~/Downloads
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH (add this to your ~/.bashrc or ~/.zshrc)
export PATH="$PATH:$HOME/Downloads/flutter/bin"

# Verify installation
flutter doctor

# Install Android toolchain
flutter doctor --android-licenses
```

### Step 2: Install Dependencies

Navigate to the project directory and install dependencies:

```bash
cd "/home/anubhavanand/Documents/alarmly pro rebuilt"

# Get Flutter packages
flutter pub get

# Generate Isar database code
flutter pub run build_runner build
```

### Step 3: Android Setup

The native Android code is already configured in `android/app/src/main/kotlin/`. No additional setup required!

**Important Permissions** (already in AndroidManifest.xml):
- `SCHEDULE_EXACT_ALARM` - Schedule exact alarms
- `USE_EXACT_ALARM` - Auto-granted for alarm apps (Android 13+)
- `WAKE_LOCK` - Keep device awake
- `RECEIVE_BOOT_COMPLETED` - Reschedule after reboot
- `FOREGROUND_SERVICE` - Run alarm service

### Step 4: iOS Setup (Optional - for iOS testing)

For iOS Critical Alerts (recommended but not required):

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Request the `com.apple.developer.usernotifications.critical-alerts` entitlement
3. Add to `ios/Runner/Runner.entitlements`:

```xml
<key>com.apple.developer.usernotifications.critical-alerts</key>
<true/>
```

## 🚀 Running the App

### Android (Recommended for initial testing)

```bash
# List connected devices
flutter devices

# Run on connected Android device/emulator
flutter run

# Or build APK
flutter build apk --release
```

### iOS

```bash
# Run on iOS simulator
flutter run -d ios

# Or build for iOS device
flutter build ios
```

## 📱 Testing the Alarm

### Phase 0 Validation (Critical Test!)

To verify the alarm survives even in extreme conditions:

1. **Set an alarm for 2 minutes from now**
2. **Enable Airplane Mode** ✈️
3. **Lock the device** 🔒
4. **Wait for alarm to ring**

✅ **Expected Result**: Alarm should ring at exact time, device should wake up, and full-screen alarm should appear.

### Additional Tests

1. **Doze Mode Test**:
   - Set alarm for 5 minutes
   - Put phone face-down on table
   - Don't touch it
   - Alarm should still ring

2. **Kill App Test**:
   - Set alarm
   - Force-stop the app from Settings → Apps
   - Alarm should still ring

3. **Reboot Test**:
   - Set alarm
   - Reboot device
   - Alarm should be restored and still ring

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── alarm.dart               # Isar database model
├── services/
│   ├── alarm_service.dart       # Alarm scheduling logic
│   └── notification_service.dart # Notification handling
├── screens/
│   ├── home_screen.dart         # Main alarm list
│   ├── alarm_edit_screen.dart   # Alarm configuration
│   └── alarm_ring_screen.dart   # Alarm + mission screen
└── missions/
    ├── math_mission.dart        # Math problem mission
    ├── shake_mission.dart       # Shake phone mission
    └── ... (more missions)

android/app/src/main/kotlin/com/wakemeup/wake_me_up_pro/
├── MainActivity.kt              # MethodChannel bridge
├── AlarmReceiver.kt             # Handles alarm trigger
├── AlarmService.kt              # Foreground service
├── AlarmScheduler.kt            # AlarmManager wrapper
├── BootReceiver.kt              # Post-boot rescheduling
└── AlarmRingActivity.kt         # Full-screen overlay
```

## 🎨 Customization

### Adding New Missions

1. Create a new file in `lib/missions/your_mission.dart`
2. Extend `StatefulWidget` with required parameters:
   ```dart
   class YourMission extends StatefulWidget {
     final int difficulty;
     final VoidCallback onComplete;
     // ... implement mission logic
   }
   ```

3. Add to `MissionType` enum in `lib/models/alarm.dart`
4. Update `AlarmRingScreen` to handle your mission

### Changing Theme

Edit `lib/main.dart` → `ThemeData`:

```dart
colorScheme: ColorScheme.dark(
  primary: const Color(0xFFYOUR_COLOR),
  // ... customize colors
)
```

## 🐛 Troubleshooting

### Alarm Not Ringing

1. **Check permissions**: Settings → Apps → Wake Me Up Pro → Permissions
2. **Disable battery optimization**: Settings → Battery → Battery Optimization → Wake Me Up Pro → Don't optimize
3. **Allow auto-start**: Some manufacturers require this (Xiaomi, Huawei, etc.)

### Build Errors

```bash
# Clean build
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Rebuild
flutter run
```

### Isar Database Errors

```bash
# Regenerate Isar schema
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📚 Next Steps

Now that you have the foundation, you can:

1. ✅ **Test Phase 0** - Verify alarms survive Doze mode
2. 🎨 **Customize UI** - Make it match your style
3. 🧠 **Add More Missions** - Implement squat, barcode, etc.
4. 📱 **iOS Support** - Configure Critical Alerts
5. 🚀 **Publish** - Deploy to Play Store/App Store

## 📖 Technical References

- [Android AlarmManager](https://developer.android.com/reference/android/app/AlarmManager)
- [Doze Mode Optimization](https://developer.android.com/training/monitoring-device-state/doze-standby)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Isar Database](https://isar.dev/)
- [Google ML Kit](https://developers.google.com/ml-kit)

## 🤝 Contributing

This is your personal project! Feel free to:
- Add new missions
- Improve UI/UX
- Optimize performance
- Fix bugs

## 📄 License

MIT License - Build something awesome! 🚀

---

**Built with ❤️ by a 3rd year CSE student**

*"The only alarm clock that guarantees you won't oversleep"* ⏰

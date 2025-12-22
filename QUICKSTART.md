# 🚀 Quick Start Guide - Wake Me Up Pro

## ⚡ Get Started in 5 Minutes!

This guide will get you from zero to running alarm app in under 5 minutes.

### Step 1: Install Flutter (if not installed)

```bash
# Quick Flutter installation (Linux/macOS)
cd ~
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$HOME/flutter/bin"

# Verify
flutter doctor
```

For detailed Flutter installation, visit: https://docs.flutter.dev/get-started/install

### Step 2: Navigate to Project

```bash
cd "/home/anubhavanand/Documents/alarmly pro rebuilt"
```

### Step 3: Install Dependencies

```bash
# Get all packages
flutter pub get

# Generate database code (Isar)
flutter pub run build_runner build
```

### Step 4: Run the App

```bash
# Connect your Android phone via USB
# Enable USB Debugging in Developer Options

# Run on device
flutter run
```

That's it! 🎉

---

## 🧪 Testing Checklist

After launching the app, test these critical features:

### ✅ Basic Functionality
- [ ] Create a new alarm
- [ ] Set time to 1 minute from now
- [ ] Save alarm
- [ ] Wait for alarm to ring

### ✅ Mission Testing
- [ ] Complete math mission
- [ ] Complete shake mission
- [ ] Verify alarm stops after mission completion

### ✅ Reliability Testing (Critical!)
- [ ] Set alarm for 2 minutes
- [ ] Force-stop app from Settings
- [ ] Alarm should still ring ✅

### ✅ Doze Mode Test
- [ ] Set alarm for 5 minutes
- [ ] Enable Airplane Mode
- [ ] Lock device and don't touch it
- [ ] Alarm should still ring ✅

---

## 🎯 Your Development Roadmap

### Week 1: Foundation ✅
You have completed:
- ✅ Project structure
- ✅ Native Android alarm daemon
- ✅ Math mission
- ✅ Shake mission
- ✅ Database (Isar)
- ✅ Home screen & alarm editor

### Week 2: Advanced Missions
Add these missions:
- [ ] **Squat Mission** (ML Kit pose detection)
  - Copy pattern from `shake_mission.dart`
  - Integrate Google ML Kit
  - Detect knee bend angle

- [ ] **Barcode Mission**
  - Use `mobile_scanner` package
  - User scans preset barcode (e.g., bathroom product)
  
- [ ] **Photo Mission**
  - Take photo of specific location
  - Compare with reference photo

### Week 3: Polish & Features
- [ ] Sound selection (custom alarm sounds)
- [ ] Gradual volume increase
- [ ] Snooze options (with missions)
- [ ] Statistics (wake-up times, missions completed)
- [ ] Themes & customization

### Week 4: iOS Support
- [ ] Submit Critical Alerts request to Apple
- [ ] Implement iOS notification cascade
- [ ] Test on iOS device

---

## 💡 Pro Tips

### Prevent Battery Optimization Kill
On some devices (especially Xiaomi, Huawei, Oppo), you need to manually disable battery optimization:

**Xiaomi MIUI**:
1. Settings → Battery → Battery Saver → Wake Me Up Pro → No restrictions
2. Settings → Apps → Manage Apps → Wake Me Up Pro → Autostart → Enable

**Huawei EMUI**:
1. Settings → Battery → App Launch → Wake Me Up Pro → Manage manually
2. Enable all three options

**Samsung One UI**:
1. Settings → Battery → Background usage limits → Never sleeping apps → Add Wake Me Up Pro

### Debug Alarm Issues

If alarm doesn't ring:

```bash
# Check Android logs
flutter run
# Then in another terminal:
adb logcat | grep "AlarmReceiver\|AlarmService"
```

### Clean Build (if errors occur)

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

---

## 📱 Building APK for Testing

```bash
# Build release APK
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎨 Customization Ideas

### Change App Colors
Edit `lib/main.dart` → Line 45:
```dart
colorScheme: ColorScheme.dark(
  primary: const Color(0xFF00F5FF), // Your color here!
  secondary: const Color(0xFFFF00FF),
)
```

### Add Custom Alarm Sound
1. Create `assets/sounds/` folder
2. Add your `.mp3` file
3. Update `pubspec.yaml`:
   ```yaml
   assets:
     - assets/sounds/my_alarm.mp3
   ```
4. Reference in alarm settings

### Change App Name
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application android:label="Your App Name">
```

---

## 🆘 Common Errors & Fixes

### Error: "Isar schema not found"
**Fix**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: "Permission denied for exact alarms"
**Fix**: 
- Go to Android Settings → Apps → Wake Me Up Pro → Set alarms and reminders → Allow

### Error: "Flutter command not found"
**Fix**: 
```bash
export PATH="$PATH:$HOME/flutter/bin"
# Add to ~/.bashrc to make permanent
```

---

## 📚 Learning Resources

### Flutter
- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)

### Android Alarms
- [AlarmManager Guide](https://developer.android.com/training/scheduling/alarms)
- [Doze Mode Best Practices](https://developer.android.com/training/monitoring-device-state/doze-standby)

### Isar Database
- [Isar Documentation](https://isar.dev/tutorials/quickstart.html)

---

## 🎓 Next Learning Steps

1. **Study the code**: Read through each file to understand the architecture
2. **Modify missions**: Change difficulty formulas, add animations
3. **Add features**: Implement your own creative wake-up methods
4. **Optimize**: Profile app performance, reduce battery usage
5. **Deploy**: Publish to Google Play Store

---

## 💬 Need Help?

If you encounter issues:
1. Check the error logs: `flutter run` shows detailed errors
2. Read the README.md for detailed explanations
3. Review the inline code comments
4. Search for specific error messages online

---

**Remember**: This is YOUR project. Experiment, break things, fix them, and learn! 🚀

*Happy coding!* 👨‍💻

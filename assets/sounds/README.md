# Sound Assets

This directory should contain alarm sound files.

## Default Sounds

You can add your own alarm sounds here. Supported formats:
- `.mp3` (recommended)
- `.wav`
- `.ogg`

## File Naming Convention

Use descriptive names:
- `gentle_bell.mp3`
- `loud_buzzer.mp3`
- `rooster.mp3`

## Adding Sounds

1. Place your sound files in this directory
2. Update `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/sounds/
   ```

## Default Behavior

Currently, the app uses the system default alarm sound via:
```kotlin
RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
```

To use custom sounds, modify `AlarmService.kt` to load from assets instead.

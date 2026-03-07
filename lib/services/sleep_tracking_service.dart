import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sleep_record.dart';

/// Service that manages automatic and manual sleep tracking.
///
/// Responsibilities:
/// - Persist user settings (bedtime, auto-tracking flag, bedtime-reminder flag).
/// - Collect accelerometer data and estimate sleep phases.
/// - Auto-detect sleep onset when the app is backgrounded during the bedtime
///   window and the phone is stationary for ≥15 minutes.
/// - Persist completed [SleepRecord]s to the Isar database.
/// - Expose live tracking state via [stateStream].
class SleepTrackingService {
  static SleepTrackingService? _instance;

  /// Returns the singleton instance.  Must call [initialize] first.
  static SleepTrackingService get instance {
    assert(_instance != null, 'SleepTrackingService.initialize() not called');
    return _instance!;
  }

  final Isar _isar;

  // ── Settings ──────────────────────────────────────────────────────────────
  bool _autoSleepTrackingEnabled = false;
  bool _bedtimeReminderEnabled = false;
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 0);

  // ── Accelerometer thresholds & constants ─────────────────────────────────

  /// Minimum movement magnitude (m/s²) below which the device is considered
  /// stationary.  Calibrated empirically against a resting phone on a mattress.
  static const double _stationaryThreshold = 0.05;

  /// Number of accelerometer samples that correspond to roughly 10 minutes,
  /// assuming a sensor update rate of ~10 Hz (10 samples/s × 60 s × 10 min).
  static const int _samplesPerTenMinutes = 6000;

  // Sleep-phase movement thresholds (m/s² delta between consecutive samples):
  //   > 1.5  → clearly awake / tossing-and-turning
  //   > 0.8  → light sleep (some movement)
  //   > 0.3  → REM sleep (occasional small movements)
  //   ≤ 0.3  → deep sleep (very little movement)
  static const double _awakeThreshold = 1.5;
  static const double _lightSleepThreshold = 0.8;
  static const double _remSleepThreshold = 0.3;

  // ── Active-tracking state ─────────────────────────────────────────────────
  bool _isTracking = false;
  bool _isAutoTracking = false;
  DateTime? _bedTime;

  StreamSubscription? _accelerometerSub;
  Timer? _autoDetectTimer;

  // Accelerometer accumulators
  double _lastMagnitude = 0;
  double _movementSum = 0;
  int _movementSampleCount = 0;
  double _currentMovement = 0;

  // Collected sleep data
  final List<double> _movementData = [];
  final List<SleepPhase> _sleepPhases = [];

  // Auto-detect accumulators (used before tracking officially begins)
  double _detectMovementSum = 0;
  int _detectSampleCount = 0;
  int _stationaryMinutes = 0;
  StreamSubscription? _detectAccelSub;

  // ── State stream ──────────────────────────────────────────────────────────
  final _stateController =
      StreamController<SleepTrackingState>.broadcast();

  /// Stream of [SleepTrackingState] updates, suitable for StreamBuilder widgets.
  Stream<SleepTrackingState> get stateStream => _stateController.stream;

  SleepTrackingService._(this._isar);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Create and initialise the singleton.  Must be called once at app start.
  static Future<SleepTrackingService> initialize(Isar isar) async {
    _instance = SleepTrackingService._(isar);
    await _instance!._loadSettings();
    return _instance!;
  }

  /// Release resources.
  void dispose() {
    _accelerometerSub?.cancel();
    _detectAccelSub?.cancel();
    _autoDetectTimer?.cancel();
    _stateController.close();
    _instance = null;
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get isTracking => _isTracking;
  bool get isAutoTracking => _isAutoTracking;
  bool get autoSleepTrackingEnabled => _autoSleepTrackingEnabled;
  bool get bedtimeReminderEnabled => _bedtimeReminderEnabled;
  TimeOfDay get bedtime => _bedtime;
  DateTime? get bedTime => _bedTime;
  double get currentMovement => _currentMovement;

  // ── Settings persistence ──────────────────────────────────────────────────

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSleepTrackingEnabled =
        prefs.getBool('auto_sleep_tracking') ?? false;
    _bedtimeReminderEnabled =
        prefs.getBool('bedtime_reminder') ?? false;
    final hour = prefs.getInt('bedtime_hour') ?? 22;
    final minute = prefs.getInt('bedtime_minute') ?? 0;
    _bedtime = TimeOfDay(hour: hour, minute: minute);
  }

  /// Persist updated settings.  Pass only the fields you want to change.
  Future<void> saveSettings({
    bool? autoSleepTracking,
    bool? bedtimeReminder,
    TimeOfDay? bedtime,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (autoSleepTracking != null) {
      _autoSleepTrackingEnabled = autoSleepTracking;
      await prefs.setBool('auto_sleep_tracking', autoSleepTracking);
    }
    if (bedtimeReminder != null) {
      _bedtimeReminderEnabled = bedtimeReminder;
      await prefs.setBool('bedtime_reminder', bedtimeReminder);
    }
    if (bedtime != null) {
      _bedtime = bedtime;
      await prefs.setInt('bedtime_hour', bedtime.hour);
      await prefs.setInt('bedtime_minute', bedtime.minute);
    }
  }

  // ── Tracking control ──────────────────────────────────────────────────────

  /// Start sleep tracking.
  ///
  /// [auto] – true when started by the auto-detection path.
  /// [detectedBedTime] – estimated actual bed-time when started automatically
  ///   (may be earlier than "now" if stationary for several minutes).
  void startTracking({bool auto = false, DateTime? detectedBedTime}) {
    if (_isTracking) return;

    _stopAutoDetection();

    _isTracking = true;
    _isAutoTracking = auto;
    _bedTime = detectedBedTime ?? DateTime.now();

    _movementData.clear();
    _sleepPhases.clear();
    _movementSum = 0;
    _movementSampleCount = 0;
    _currentMovement = 0;
    _lastMagnitude = 0;

    _startAccelerometer();

    _emitState(
      SleepTrackingState(
        isTracking: true,
        isAutoTracking: auto,
        bedTime: _bedTime,
        currentPhase: SleepPhase.awake,
        currentMovement: 0,
      ),
    );
  }

  /// Stop tracking, build a [SleepRecord], save it and return it.
  Future<SleepRecord?> stopTracking() async {
    if (!_isTracking || _bedTime == null) return null;

    final wakeTime = DateTime.now();

    _accelerometerSub?.cancel();
    _accelerometerSub = null;

    _isTracking = false;
    _isAutoTracking = false;

    // Flush any partial 10-minute window
    if (_movementSampleCount > 0) {
      final avg = _movementSum / _movementSampleCount;
      _movementData.add(avg);
      _addPhase(avg);
    }

    final record = _buildRecord(wakeTime);

    await _isar.writeTxn(() async {
      await _isar.sleepRecords.put(record);
    });

    _emitState(const SleepTrackingState(isTracking: false));
    return record;
  }

  // ── App-lifecycle hooks ───────────────────────────────────────────────────

  /// Call when the app enters the background.
  ///
  /// If auto-sleep-tracking is enabled and the current time falls within
  /// the configured bedtime window, begin monitoring for sleep onset.
  void onAppBackground() {
    if (_autoSleepTrackingEnabled && !_isTracking && isInBedtimeWindow) {
      _startAutoDetection();
    }
  }

  /// Call when the app returns to the foreground.
  void onAppForeground() {
    _stopAutoDetection();
  }

  // ── Bedtime window helper ─────────────────────────────────────────────────

  /// Returns true if the current time is within ±2 hours of the set bedtime.
  ///
  /// Uses modular arithmetic so the window wraps correctly around midnight.
  /// Example: bedtime = 23:00, window = [21:00, 01:00].
  bool get isInBedtimeWindow {
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    final bedMin = _bedtime.hour * 60 + _bedtime.minute;
    // Forward distance from bedtime to now in the 24-hour cycle.
    final diff = ((nowMin - bedMin) % (24 * 60) + (24 * 60)) % (24 * 60);
    // Within 2 hours before bedtime (diff ≥ 22*60) or 2 hours after (diff ≤ 120).
    return diff <= 120 || diff >= (24 * 60) - 120;
  }

  // ── Auto-detection ────────────────────────────────────────────────────────

  void _startAutoDetection() {
    _detectMovementSum = 0;
    _detectSampleCount = 0;
    _stationaryMinutes = 0;
    double lastMag = 0;

    _detectAccelSub = accelerometerEventStream().listen((event) {
      final mag = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      _detectMovementSum += (mag - lastMag).abs();
      lastMag = mag;
      _detectSampleCount++;
    });

    // Check every 5 minutes whether the device has been stationary.
    _autoDetectTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_detectSampleCount == 0) return;
      final avg = _detectMovementSum / _detectSampleCount;
      _detectMovementSum = 0;
      _detectSampleCount = 0;

      if (avg < _stationaryThreshold) {
        _stationaryMinutes += 5;
        if (_stationaryMinutes >= 15) {
          // Phone has been stationary for ≥15 min → auto-start tracking.
          _stopAutoDetection();
          final detectedBedTime =
              DateTime.now().subtract(Duration(minutes: _stationaryMinutes));
          startTracking(auto: true, detectedBedTime: detectedBedTime);
        }
      } else {
        _stationaryMinutes = 0;
      }
    });
  }

  void _stopAutoDetection() {
    _detectAccelSub?.cancel();
    _detectAccelSub = null;
    _autoDetectTimer?.cancel();
    _autoDetectTimer = null;
    _stationaryMinutes = 0;
  }

  // ── Accelerometer (active tracking) ──────────────────────────────────────

  void _startAccelerometer() {
    _accelerometerSub = accelerometerEventStream().listen((event) {
      final mag = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      final delta = (mag - _lastMagnitude).abs();
      _lastMagnitude = mag;

      _movementSum += delta;
      _movementSampleCount++;
      _currentMovement = _currentMovement * 0.9 + delta * 0.1;

      // Flush roughly every 10 minutes (see _samplesPerTenMinutes).
      if (_movementSampleCount >= _samplesPerTenMinutes) {
        final avg = _movementSum / _movementSampleCount;
        _movementData.add(avg);
        _addPhase(avg, emit: true);
        _movementSum = 0;
        _movementSampleCount = 0;
      }
    });
  }

  void _addPhase(double movement, {bool emit = false}) {
    final SleepPhase phase;
    if (movement > _awakeThreshold) {
      phase = SleepPhase.awake;
    } else if (movement > _lightSleepThreshold) {
      phase = SleepPhase.light;
    } else if (movement > _remSleepThreshold) {
      phase = SleepPhase.rem;
    } else {
      phase = SleepPhase.deep;
    }
    _sleepPhases.add(phase);

    if (emit) {
      _emitState(
        SleepTrackingState(
          isTracking: true,
          isAutoTracking: _isAutoTracking,
          bedTime: _bedTime,
          currentPhase: phase,
          currentMovement: _currentMovement,
        ),
      );
    }
  }

  // ── Record builder ────────────────────────────────────────────────────────

  SleepRecord _buildRecord(DateTime wakeTime) {
    int deepMin = 0, lightMin = 0, remMin = 0, awakeMin = 0;
    for (final phase in _sleepPhases) {
      switch (phase) {
        case SleepPhase.deep:
          deepMin += 10;
          break;
        case SleepPhase.light:
          lightMin += 10;
          break;
        case SleepPhase.rem:
          remMin += 10;
          break;
        case SleepPhase.awake:
          awakeMin += 10;
          break;
      }
    }

    final totalMin = wakeTime.difference(_bedTime!).inMinutes;
    final efficiency =
        totalMin > 0 ? ((totalMin - awakeMin) / totalMin * 100).round() : 0;
    final deepRatio = totalMin > 0 ? (deepMin / totalMin * 100) : 0.0;
    final quality =
        ((efficiency + deepRatio) / 2).round().clamp(0, 100);

    return SleepRecord.create(
      bedTime: _bedTime!,
      wakeTime: wakeTime,
      sleepQuality: quality,
      deepSleepMinutes: deepMin,
      lightSleepMinutes: lightMin,
      remSleepMinutes: remMin,
      awakeMinutes: awakeMin,
      movementData: List<double>.from(_movementData),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _emitState(SleepTrackingState state) {
    if (!_stateController.isClosed) _stateController.add(state);
  }
}

/// Immutable snapshot of the current sleep-tracking state.
class SleepTrackingState {
  final bool isTracking;
  final bool isAutoTracking;
  final DateTime? bedTime;
  final SleepPhase currentPhase;
  final double currentMovement;

  const SleepTrackingState({
    required this.isTracking,
    this.isAutoTracking = false,
    this.bedTime,
    this.currentPhase = SleepPhase.awake,
    this.currentMovement = 0,
  });
}

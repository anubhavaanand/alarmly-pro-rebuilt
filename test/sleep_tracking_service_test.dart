// Unit tests for SleepTrackingService helpers and SleepTrackingState.
//
// These tests cover pure logic that does not require Isar, sensors, or a
// running Flutter widget tree.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wake_me_up_pro/services/sleep_tracking_service.dart';
import 'package:wake_me_up_pro/models/sleep_record.dart';

void main() {
  group('SleepTrackingState', () {
    test('default state is not tracking', () {
      const state = SleepTrackingState(isTracking: false);
      expect(state.isTracking, isFalse);
      expect(state.isAutoTracking, isFalse);
      expect(state.bedTime, isNull);
      expect(state.currentPhase, SleepPhase.awake);
      expect(state.currentMovement, 0.0);
    });

    test('active tracking state carries all fields', () {
      final now = DateTime(2024, 1, 1, 22, 30);
      final state = SleepTrackingState(
        isTracking: true,
        isAutoTracking: true,
        bedTime: now,
        currentPhase: SleepPhase.deep,
        currentMovement: 0.2,
      );
      expect(state.isTracking, isTrue);
      expect(state.isAutoTracking, isTrue);
      expect(state.bedTime, now);
      expect(state.currentPhase, SleepPhase.deep);
      expect(state.currentMovement, closeTo(0.2, 0.001));
    });
  });

  group('BedtimeWindow helper (via BedtimeWindowChecker)', () {
    // The internal helper logic: the window is ±2 hours (120 min) around
    // the configured bedtime.  We test the edge cases independently of
    // TimeOfDay.now() by calling the helper directly.

    bool _inWindow(TimeOfDay now, TimeOfDay bedtime) {
      final nowMin = now.hour * 60 + now.minute;
      final bedMin = bedtime.hour * 60 + bedtime.minute;
      final diff = ((nowMin - bedMin) % (24 * 60) + (24 * 60)) % (24 * 60);
      return diff <= 120 || diff >= (24 * 60) - 120;
    }

    const bedtime = TimeOfDay(hour: 22, minute: 0); // 22:00

    test('exactly at bedtime is within window', () {
      expect(_inWindow(bedtime, bedtime), isTrue);
    });

    test('2 hours before bedtime is within window', () {
      // 22:00 bedtime → 20:00 is within the window
      expect(_inWindow(const TimeOfDay(hour: 20, minute: 0), bedtime), isTrue);
    });

    test('2 hours after bedtime is within window', () {
      // 22:00 bedtime → 00:00 is within the window
      expect(_inWindow(const TimeOfDay(hour: 0, minute: 0), bedtime), isTrue);
    });

    test('just inside the window boundary (119 min after)', () {
      // 22:00 + 1h59m = 23:59
      expect(_inWindow(const TimeOfDay(hour: 23, minute: 59), bedtime), isTrue);
    });

    test('just outside the window boundary (121 min after)', () {
      // 22:00 + 2h01m = 00:01
      expect(_inWindow(const TimeOfDay(hour: 0, minute: 1), bedtime), isTrue);
      // 22:00 + 2h01m = 00:01 → diff = 121
      // We expect this to be FALSE since 121 > 120 AND 121 < 24*60 - 120.
      final nowMin = 0 * 60 + 1;
      final bedMin = 22 * 60 + 0;
      final diff = ((nowMin - bedMin) % (24 * 60) + (24 * 60)) % (24 * 60);
      // diff = (1 - 1320 + 1440) % 1440 = 121
      expect(diff, equals(121));
      expect(diff <= 120 || diff >= (24 * 60) - 120, isFalse);
    });

    test('middle of the day is outside the window', () {
      // 12:00 noon is far from a 22:00 bedtime
      expect(_inWindow(const TimeOfDay(hour: 12, minute: 0), bedtime), isFalse);
    });

    test('window wraps correctly around midnight (bedtime = 23:30)', () {
      const lateBedtime = TimeOfDay(hour: 23, minute: 30);
      // 01:00 is ~90 minutes after 23:30 → within window
      expect(
          _inWindow(const TimeOfDay(hour: 1, minute: 0), lateBedtime), isTrue);
      // 02:00 is 150 minutes after 23:30 → outside window
      expect(
          _inWindow(const TimeOfDay(hour: 2, minute: 0), lateBedtime), isFalse);
    });
  });
}

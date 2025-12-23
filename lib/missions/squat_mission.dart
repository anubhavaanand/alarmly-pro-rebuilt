import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// SquatMission - A simplified squat detection mission using accelerometer
/// Note: For full pose detection, integrate google_mlkit_pose_detection
/// This version uses accelerometer to detect up/down motion patterns
class SquatMission extends StatefulWidget {
  final int difficulty; // 1-5
  final VoidCallback onComplete;
  
  const SquatMission({
    Key? key,
    required this.difficulty,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<SquatMission> createState() => _SquatMissionState();
}

class _SquatMissionState extends State<SquatMission> {
  int _squatCount = 0;
  late int _targetSquats;
  StreamSubscription? _accelerometerSubscription;
  
  // Squat detection state
  bool _isGoingDown = false;
  bool _isAtBottom = false;
  double _lastY = 0;
  double _minY = 0;
  DateTime _lastSquatTime = DateTime.now();
  
  // Detection thresholds
  static const double _downThreshold = -2.0; // Negative Y when going down
  static const double _upThreshold = 2.0;    // Positive Y when going up
  static const int _minSquatIntervalMs = 800; // Min time per squat
  
  @override
  void initState() {
    super.initState();
    
    // Calculate target squats based on difficulty (3-15 squats)
    _targetSquats = 3 + (widget.difficulty - 1) * 3;
    
    _startListening();
  }
  
  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
  
  void _startListening() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      final now = DateTime.now();
      final timeSinceLastSquat = now.difference(_lastSquatTime).inMilliseconds;
      
      // Simple state machine for squat detection
      // Phase 1: Going down (Y acceleration becomes negative)
      if (!_isGoingDown && event.y < _downThreshold) {
        _isGoingDown = true;
        _minY = event.y;
      }
      
      // Track minimum Y during descent
      if (_isGoingDown && event.y < _minY) {
        _minY = event.y;
      }
      
      // Phase 2: At bottom (Y stabilizes or starts going up)
      if (_isGoingDown && !_isAtBottom && event.y > _minY + 1.0) {
        _isAtBottom = true;
      }
      
      // Phase 3: Going up (Y becomes positive = completing squat)
      if (_isAtBottom && event.y > _upThreshold && 
          timeSinceLastSquat > _minSquatIntervalMs) {
        // Squat completed!
        _isGoingDown = false;
        _isAtBottom = false;
        _minY = 0;
        _lastSquatTime = now;
        
        if (mounted) {
          setState(() {
            _squatCount++;
          });
          
          // Check if mission complete
          if (_squatCount >= _targetSquats) {
            _accelerometerSubscription?.cancel();
            widget.onComplete();
          }
        }
      }
      
      _lastY = event.y;
    });
  }
  
  double get _progress => _squatCount / _targetSquats;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              const Text(
                '🏋️ Do Squats!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms),
              
              const SizedBox(height: 16),
              
              Text(
                'Hold your phone and do squats',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // Circular progress with squat counter
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle with glow
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1A2E),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF00FF).withOpacity(_progress * 0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  
                  // Progress circle
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(
                          const Color(0xFFFF00FF),
                          const Color(0xFF00FF88),
                          _progress,
                        )!,
                      ),
                    ),
                  ),
                  
                  // Counter and icon
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🏋️',
                        style: const TextStyle(fontSize: 48),
                      )
                          .animate(
                            onPlay: (controller) => controller.repeat(),
                          )
                          .scaleXY(
                            begin: 1.0,
                            end: 1.2,
                            duration: 500.ms,
                          )
                          .then()
                          .scaleXY(
                            begin: 1.2,
                            end: 1.0,
                            duration: 500.ms,
                          ),
                      const SizedBox(height: 8),
                      Text(
                        '$_squatCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'of $_targetSquats squats',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 60),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF00FF).withOpacity(0.2),
                      const Color(0xFF00F5FF).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'How to do it:',
                      style: TextStyle(
                        color: Color(0xFF00F5FF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Hold phone in your hand\n'
                      '2. Stand up straight\n'
                      '3. Squat down and stand back up\n'
                      '4. Repeat until complete',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Status indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _isGoingDown
                      ? const Color(0xFFFF00FF).withOpacity(0.3)
                      : _isAtBottom
                          ? const Color(0xFFFFD700).withOpacity(0.3)
                          : const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isAtBottom
                      ? '⬆️ Now stand up!'
                      : _isGoingDown
                          ? '⬇️ Going down...'
                          : '🧍 Start squatting',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(
                      const Color(0xFFFF00FF),
                      const Color(0xFF00FF88),
                      _progress,
                    )!,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

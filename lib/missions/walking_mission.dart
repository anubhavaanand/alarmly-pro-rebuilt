import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WalkingMission extends StatefulWidget {
  final int difficulty; // 1-5
  final VoidCallback onComplete;
  
  const WalkingMission({
    Key? key,
    required this.difficulty,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<WalkingMission> createState() => _WalkingMissionState();
}

class _WalkingMissionState extends State<WalkingMission> {
  int _stepCount = 0;
  late int _targetSteps;
  StreamSubscription? _accelerometerSubscription;
  
  // Step detection variables
  double _lastMagnitude = 0;
  bool _isStepUp = false;
  DateTime _lastStepTime = DateTime.now();
  
  // Step detection thresholds
  static const double _stepThreshold = 12.0;
  static const int _minStepIntervalMs = 250; // Minimum time between steps
  
  @override
  void initState() {
    super.initState();
    
    // Calculate target steps based on difficulty (10-50 steps)
    _targetSteps = 10 + (widget.difficulty - 1) * 10;
    
    _startListening();
  }
  
  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
  
  void _startListening() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      // Calculate magnitude of acceleration
      final double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );
      
      final now = DateTime.now();
      final timeSinceLastStep = now.difference(_lastStepTime).inMilliseconds;
      
      // Step detection using peak detection algorithm
      if (!_isStepUp && magnitude > _stepThreshold && 
          timeSinceLastStep > _minStepIntervalMs) {
        _isStepUp = true;
        _lastStepTime = now;
        
        if (mounted) {
          setState(() {
            _stepCount++;
          });
          
          // Check if mission complete
          if (_stepCount >= _targetSteps) {
            _accelerometerSubscription?.cancel();
            widget.onComplete();
          }
        }
      } else if (_isStepUp && magnitude < _stepThreshold - 2) {
        _isStepUp = false;
      }
      
      _lastMagnitude = magnitude;
    });
  }
  
  double get _progress => _stepCount / _targetSteps;

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
                '🚶 Start Walking!',
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
                'Walk around to wake yourself up',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // Circular progress
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1A2E),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF88).withOpacity(_progress * 0.3),
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
                  
                  // Counter
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.directions_walk,
                        color: Color(0xFF00F5FF),
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_stepCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'of $_targetSteps steps',
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
              
              // Walking animation indicator
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00FF88).withOpacity(0.2),
                      const Color(0xFF00F5FF).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 40,
                      color: Colors.white.withOpacity(0.8),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .moveY(begin: 0, end: -5, duration: 500.ms)
                        .then()
                        .moveY(begin: -5, end: 0, duration: 500.ms),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.directions_walk,
                      size: 40,
                      color: Colors.white.withOpacity(0.6),
                    )
                        .animate(onPlay: (controller) => controller.repeat(), delay: 250.ms)
                        .moveY(begin: 0, end: -5, duration: 500.ms)
                        .then()
                        .moveY(begin: -5, end: 0, duration: 500.ms),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.directions_walk,
                      size: 40,
                      color: Colors.white.withOpacity(0.4),
                    )
                        .animate(onPlay: (controller) => controller.repeat(), delay: 500.ms)
                        .moveY(begin: 0, end: -5, duration: 500.ms)
                        .then()
                        .moveY(begin: -5, end: 0, duration: 500.ms),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
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

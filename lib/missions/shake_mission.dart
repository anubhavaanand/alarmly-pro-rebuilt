import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ShakeMission extends StatefulWidget {
  final int difficulty; // 1-5
  final VoidCallback onComplete;
  
  const ShakeMission({
    Key? key,
    required this.difficulty,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<ShakeMission> createState() => _ShakeMissionState();
}

class _ShakeMissionState extends State<ShakeMission> with SingleTickerProviderStateMixin {
  int _shakeCount = 0;
  late int _targetShakes;
  double _lastAcceleration = 0;
  StreamSubscription? _accelerometerSubscription;
  late AnimationController _pulseController;
  
  static const double _shakeThreshold = 15.0; // Acceleration threshold for shake detection
  
  @override
  void initState() {
    super.initState();
    
    // Calculate target shakes based on difficulty (20-100 shakes)
    _targetShakes = 20 + (widget.difficulty - 1) * 20;
    
    // Set up pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    // Start listening to accelerometer
    _startListening();
  }
  
  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
  
  void _startListening() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      // Calculate magnitude: sqrt(x² + y² + z²)
      final double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );
      
      // Detect significant change from baseline (gravity = 9.8 m/s²)
      if ((acceleration - _lastAcceleration).abs() > _shakeThreshold) {
        if (mounted) {
          setState(() {
            _shakeCount++;
          });
          
          // Check if mission complete
          if (_shakeCount >= _targetShakes) {
            _accelerometerSubscription?.cancel();
            widget.onComplete();
          }
        }
      }
      
      _lastAcceleration = acceleration;
    });
  }
  
  double get _progress => _shakeCount / _targetShakes;

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
                'SHAKE YOUR PHONE!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms),
              
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
                          color: const Color(0xFF00F5FF).withOpacity(_progress * 0.3),
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
                          const Color(0xFF00F5FF),
                          _progress,
                        )!,
                      ),
                    ),
                  ),
                  
                  // Counter
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_shakeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'of $_targetShakes',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.05, 1.05),
                    duration: 1000.ms,
                  ),
              
              const SizedBox(height: 60),
              
              // Phone shake icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00F5FF).withOpacity(0.2),
                      const Color(0xFFFF00FF).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.phone_android,
                  size: 80,
                  color: Colors.white,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shake(duration: 500.ms, hz: 4, rotation: 0.05),
              
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

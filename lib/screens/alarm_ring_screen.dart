import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/alarm.dart';
import '../missions/math_mission.dart';
import '../missions/shake_mission.dart';
import '../missions/memory_mission.dart';
import '../missions/typing_mission.dart';
import '../missions/barcode_mission.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';

class AlarmRingScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  
  const AlarmRingScreen({Key? key, this.initialData}) : super(key: key);

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  late int _alarmId;
  late MissionType _missionType;
  late int _difficulty;
  bool _missionStarted = false;
  bool _initialized = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_initialized) return;
    _initialized = true;
    
    // Get alarm data from widget or route arguments
    Map<String, dynamic>? args = widget.initialData;
    if (args == null) {
      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      if (routeArgs is Map<String, dynamic>) {
        args = routeArgs;
      }
    }
    
    _alarmId = args?['alarmId'] ?? 0;
    _missionType = _parseMissionType(args?['missionType'] ?? 'math');
    _difficulty = args?['difficulty'] ?? 3;
    
    // Keep screen on
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }
  
  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
  
  MissionType _parseMissionType(String type) {
    switch (type) {
      case 'shake':
        return MissionType.shake;
      case 'squat':
        return MissionType.squat;
      case 'barcode':
        return MissionType.barcode;
      case 'memory':
        return MissionType.memory;
      case 'typing':
        return MissionType.typing;
      case 'photo':
        return MissionType.photo;
      case 'walking':
        return MissionType.walking;
      default:
        return MissionType.math;
    }
  }
  
  void _onMissionComplete() async {
    // Stop alarm sound
    await AlarmService.stopAlarm();
    
    // Schedule wake-up verification
    await NotificationService.scheduleWakeUpCheck(_alarmId);
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Alarm dismissed! Stay awake...'),
          backgroundColor: Color(0xFF00FF88),
        ),
      );
      
      // Return to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_missionStarted) {
      return _buildMissionIntro();
    }
    
    // Show the appropriate mission
    switch (_missionType) {
      case MissionType.math:
        return MathMission(
          difficulty: _difficulty,
          onComplete: _onMissionComplete,
        );
        
      case MissionType.shake:
        return ShakeMission(
          difficulty: _difficulty,
          onComplete: _onMissionComplete,
        );
        
      case MissionType.memory:
        return MemoryMission(
          difficulty: _difficulty,
          onComplete: _onMissionComplete,
        );
        
      case MissionType.typing:
        return TypingMission(
          difficulty: _difficulty,
          onComplete: _onMissionComplete,
        );
        
      case MissionType.barcode:
        return BarcodeMission(
          difficulty: _difficulty,
          onComplete: _onMissionComplete,
        );
        
      // Fallback for not-yet-implemented missions
      case MissionType.squat:
      case MissionType.photo:
      case MissionType.walking:
      default:
        // Default to math for unimplemented missions
        return MathMission(
          difficulty: _difficulty,
          onComplete: _onMissionComplete,
        );
    }
  }
  
  Widget _buildMissionIntro() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mission icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00F5FF),
                      const Color(0xFFFF00FF),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    _missionType.icon,
                    style: const TextStyle(fontSize: 60),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Mission title
              Text(
                'Wake Up!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Mission description
              Text(
                _missionType.displayName,
                style: const TextStyle(
                  color: Color(0xFF00F5FF),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                _missionType.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // Difficulty indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Icon(
                    index < _difficulty ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFD700),
                    size: 32,
                  );
                }),
              ),
              
              const SizedBox(height: 60),
              
              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _missionStarted = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5FF),
                    foregroundColor: const Color(0xFF0F0F1E),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Start Mission',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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

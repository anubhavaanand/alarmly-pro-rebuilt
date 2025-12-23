import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:isar/isar.dart';
import '../models/sleep_record.dart';

class SleepTrackingScreen extends StatefulWidget {
  final Isar isar;
  final DateTime? alarmTime;
  
  const SleepTrackingScreen({
    Key? key,
    required this.isar,
    this.alarmTime,
  }) : super(key: key);

  @override
  State<SleepTrackingScreen> createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen>
    with TickerProviderStateMixin {
  bool _isTracking = false;
  DateTime? _bedTime;
  Timer? _updateTimer;
  StreamSubscription? _accelerometerSubscription;
  
  // Movement tracking
  List<double> _movementData = [];
  double _currentMovement = 0;
  double _lastMagnitude = 0;
  int _movementSampleCount = 0;
  double _movementSum = 0;
  
  // Current sleep phase estimation
  SleepPhase _currentPhase = SleepPhase.awake;
  List<SleepPhase> _sleepPhases = [];
  
  // Animation controller for breathing circle
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  
  // Stats
  Duration get _elapsedTime => _bedTime != null 
      ? DateTime.now().difference(_bedTime!) 
      : Duration.zero;
  
  @override
  void initState() {
    super.initState();
    
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _breathAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _breathController.dispose();
    super.dispose();
  }
  
  void _startTracking() {
    setState(() {
      _isTracking = true;
      _bedTime = DateTime.now();
      _movementData = [];
      _sleepPhases = [];
      _currentPhase = SleepPhase.awake;
    });
    
    // Keep screen dim but on
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // Start accelerometer monitoring
    _startMovementTracking();
    
    // Update UI every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }
  
  void _startMovementTracking() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );
      
      // Calculate movement as change in acceleration
      final movement = (magnitude - _lastMagnitude).abs();
      _lastMagnitude = magnitude;
      
      _movementSum += movement;
      _movementSampleCount++;
      
      // Every 10 minutes, save average movement
      if (_movementSampleCount >= 600 * 10) { // ~10 min at 10Hz
        final avgMovement = _movementSum / _movementSampleCount;
        _movementData.add(avgMovement);
        _estimateSleepPhase(avgMovement);
        _movementSum = 0;
        _movementSampleCount = 0;
      }
      
      // Update current movement display (smoothed)
      _currentMovement = _currentMovement * 0.9 + movement * 0.1;
    });
  }
  
  void _estimateSleepPhase(double movement) {
    // Simple phase estimation based on movement
    SleepPhase phase;
    if (movement > 1.5) {
      phase = SleepPhase.awake;
    } else if (movement > 0.8) {
      phase = SleepPhase.light;
    } else if (movement > 0.3) {
      phase = SleepPhase.rem;
    } else {
      phase = SleepPhase.deep;
    }
    
    _sleepPhases.add(phase);
    setState(() {
      _currentPhase = phase;
    });
  }
  
  Future<void> _stopTracking() async {
    if (_bedTime == null) return;
    
    final wakeTime = DateTime.now();
    
    // Calculate sleep stats
    final totalMinutes = wakeTime.difference(_bedTime!).inMinutes;
    int deepMinutes = 0;
    int lightMinutes = 0;
    int remMinutes = 0;
    int awakeMinutes = 0;
    
    for (final phase in _sleepPhases) {
      switch (phase) {
        case SleepPhase.deep:
          deepMinutes += 10;
          break;
        case SleepPhase.light:
          lightMinutes += 10;
          break;
        case SleepPhase.rem:
          remMinutes += 10;
          break;
        case SleepPhase.awake:
          awakeMinutes += 10;
          break;
      }
    }
    
    // Calculate quality score
    final sleepEfficiency = totalMinutes > 0 
        ? ((totalMinutes - awakeMinutes) / totalMinutes * 100).round()
        : 0;
    final deepSleepRatio = totalMinutes > 0 
        ? (deepMinutes / totalMinutes * 100)
        : 0;
    final quality = ((sleepEfficiency + deepSleepRatio) / 2).round().clamp(0, 100);
    
    // Save sleep record
    final record = SleepRecord.create(
      bedTime: _bedTime!,
      wakeTime: wakeTime,
      sleepQuality: quality,
      deepSleepMinutes: deepMinutes,
      lightSleepMinutes: lightMinutes,
      remSleepMinutes: remMinutes,
      awakeMinutes: awakeMinutes,
      movementData: _movementData,
    );
    
    await widget.isar.writeTxn(() async {
      await widget.isar.sleepRecords.put(record);
    });
    
    // Stop tracking
    _updateTimer?.cancel();
    _accelerometerSubscription?.cancel();
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    setState(() {
      _isTracking = false;
      _bedTime = null;
    });
    
    // Show summary
    if (mounted) {
      _showSleepSummary(record);
    }
  }
  
  void _showSleepSummary(SleepRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Quality score circle
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(record.qualityColor).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${record.sleepQuality}%',
                          style: TextStyle(
                            color: Color(record.qualityColor),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          record.qualityRating,
                          style: TextStyle(
                            color: Color(record.qualityColor),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Sleep duration
                _buildSummaryRow(
                  icon: Icons.bedtime,
                  label: 'Sleep Duration',
                  value: record.sleepDurationString,
                ),
                _buildSummaryRow(
                  icon: Icons.dark_mode,
                  label: 'Deep Sleep',
                  value: '${record.deepSleepMinutes}m',
                  color: const Color(0xFF6366F1),
                ),
                _buildSummaryRow(
                  icon: Icons.waves,
                  label: 'Light Sleep',
                  value: '${record.lightSleepMinutes}m',
                  color: const Color(0xFF00F5FF),
                ),
                _buildSummaryRow(
                  icon: Icons.visibility,
                  label: 'REM Sleep',
                  value: '${record.remSleepMinutes}m',
                  color: const Color(0xFFFF00FF),
                ),
                _buildSummaryRow(
                  icon: Icons.remove_red_eye,
                  label: 'Awake Time',
                  value: '${record.awakeMinutes}m',
                  color: const Color(0xFFFF3366),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F5FF),
                      foregroundColor: const Color(0xFF0F0F1E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    Color color = const Color(0xFF00F5FF),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: _isTracking ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sleep Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isTracking ? _buildTrackingView() : _buildStartView(),
      ),
    );
  }
  
  Widget _buildStartView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          
          // Moon animation
          AnimatedBuilder(
            animation: _breathAnimation,
            builder: (context, child) => Transform.scale(
              scale: _breathAnimation.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF6366F1).withOpacity(0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🌙',
                    style: TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 1.seconds)
              .scale(begin: const Offset(0.8, 0.8)),
          
          const SizedBox(height: 48),
          
          const Text(
            'Sleep Tracking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Place your phone on the mattress\nto track your sleep patterns',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (widget.alarmTime != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.alarm,
                    color: Color(0xFF00F5FF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Alarm at ${_formatTime(widget.alarmTime!)}',
                    style: const TextStyle(
                      color: Color(0xFF00F5FF),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const Spacer(),
          
          // Features list
          _buildFeatureItem(Icons.timeline, 'Sleep cycle analysis'),
          _buildFeatureItem(Icons.bar_chart, 'Sleep quality score'),
          _buildFeatureItem(Icons.history, 'Sleep history tracking'),
          
          const SizedBox(height: 32),
          
          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bedtime, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Start Sleep Tracking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 500.ms)
              .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6366F1),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrackingView() {
    return GestureDetector(
      onTap: () {
        // Show wake up button on tap
        _showWakeUpDialog();
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Current phase indicator
            AnimatedBuilder(
              animation: _breathAnimation,
              builder: (context, child) => Transform.scale(
                scale: _breathAnimation.value,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(_currentPhase.color),
                        Color(_currentPhase.color).withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.2, 0.5, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatDuration(_elapsedTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentPhase.displayName,
                          style: TextStyle(
                            color: Color(_currentPhase.color),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Movement indicator
            Column(
              children: [
                Text(
                  'Movement',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_currentMovement / 3).clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(_currentPhase.color),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 80),
            
            Text(
              'Tap anywhere to wake up',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showWakeUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Wake Up?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'You\'ve been sleeping for ${_formatDuration(_elapsedTime)}',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Sleeping'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _stopTracking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F5FF),
              foregroundColor: const Color(0xFF0F0F1E),
            ),
            child: const Text('Wake Up'),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

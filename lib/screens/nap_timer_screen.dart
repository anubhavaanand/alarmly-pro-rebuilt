import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:isar/isar.dart';
import '../models/alarm.dart';
import '../models/alarm_stats.dart';
import '../services/alarm_service.dart';

/// Nap Timer Screen - PREMIUM FEATURE (FREE!)
class NapTimerScreen extends StatefulWidget {
  final Isar isar;
  
  const NapTimerScreen({super.key, required this.isar});

  @override
  State<NapTimerScreen> createState() => _NapTimerScreenState();
}

class _NapTimerScreenState extends State<NapTimerScreen> {
  int _selectedMinutes = 20;
  bool _isNapActive = false;
  DateTime? _napEndTime;
  String _selectedPreset = 'Power Nap';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Nap Timer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Timer display
            _buildTimerDisplay(),
            const SizedBox(height: 32),
            
            // Preset buttons
            _buildPresets(),
            const SizedBox(height: 24),
            
            // Custom time slider
            _buildCustomSlider(),
            const SizedBox(height: 32),
            
            // Mission selector
            _buildMissionSelector(),
            const SizedBox(height: 32),
            
            // Start button
            _buildStartButton(),
            const SizedBox(height: 24),
            
            // Nap tips
            _buildNapTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDisplay() {
    final hours = _selectedMinutes ~/ 60;
    final minutes = _selectedMinutes % 60;
    
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.5),
          width: 3,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '😴',
              style: TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _selectedPreset,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut);
  }

  Widget _buildPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Presets',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: NapPresets.presets.entries.map((preset) {
            final isSelected = _selectedPreset == preset.key;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPreset = preset.key;
                  _selectedMinutes = preset.value;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF6366F1)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      preset.key,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${preset.value}m',
                      style: TextStyle(
                        color: isSelected 
                            ? Colors.white.withValues(alpha: 0.8)
                            : const Color(0xFF00F5FF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Custom Duration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_selectedMinutes}m',
              style: const TextStyle(
                color: Color(0xFF00F5FF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF6366F1),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            thumbColor: const Color(0xFF00F5FF),
            overlayColor: const Color(0xFF00F5FF).withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _selectedMinutes.toDouble(),
            min: 5,
            max: 180,
            divisions: 35,
            onChanged: (value) {
              setState(() {
                _selectedMinutes = value.round();
                _selectedPreset = 'Custom';
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('5m', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            Text('3h', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ],
        ),
      ],
    );
  }

  MissionType _selectedMission = MissionType.shake;

  Widget _buildMissionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wake-Up Mission',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              MissionType.shake,
              MissionType.math,
              MissionType.memory,
              MissionType.walking,
            ].map((mission) {
              final isSelected = _selectedMission == mission;
              return GestureDetector(
                onTap: () => setState(() => _selectedMission = mission),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF00F5FF).withValues(alpha: 0.2)
                        : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF00F5FF)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(mission.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        mission.displayName,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF00F5FF) : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startNap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bedtime, size: 24),
            const SizedBox(width: 12),
            Text(
              'Start $_selectedMinutes min Nap',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildNapTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFFFFD700), size: 20),
              SizedBox(width: 8),
              Text(
                'Nap Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            NapPresets.getDescription(_selectedPreset),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Nap in a dark, quiet space\n• Avoid napping after 3 PM\n• Set a consistent nap time',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startNap() async {
    final napAlarm = Alarm.createNap(
      durationMinutes: _selectedMinutes,
      missionType: _selectedMission,
    );

    await widget.isar.writeTxn(() async {
      await widget.isar.alarms.put(napAlarm);
    });

    await AlarmService.scheduleAlarm(napAlarm);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nap alarm set for $_selectedMinutes minutes'),
          backgroundColor: const Color(0xFF6366F1),
        ),
      );
      Navigator.pop(context);
    }
  }
}

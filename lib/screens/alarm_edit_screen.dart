import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';

class AlarmEditScreen extends StatefulWidget {
  final Alarm alarm;
  final Isar isar;
  
  const AlarmEditScreen({
    Key? key,
    required this.alarm,
    required this.isar,
  }) : super(key: key);

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late TextEditingController _labelController;
  late TimeOfDay _selectedTime;
  late MissionType _selectedMission;
  late int _difficulty;
  late bool _wakeUpCheck;
  late Set<int> _repeatDays;
  
  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.alarm.label);
    _selectedTime = TimeOfDay.fromDateTime(widget.alarm.time);
    _selectedMission = widget.alarm.missionType;
    _difficulty = widget.alarm.missionDifficulty;
    _wakeUpCheck = widget.alarm.wakeUpCheckEnabled;
    _repeatDays = widget.alarm.repeatDays.toSet();
  }
  
  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarm.id == Isar.autoIncrement ? 'New Alarm' : 'Edit Alarm'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          if (widget.alarm.id != Isar.autoIncrement)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteAlarm,
              color: const Color(0xFFFF3366),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Time picker
          _buildTimeSection(),
          const SizedBox(height: 24),
          
          // Label
          _buildLabelSection(),
          const SizedBox(height: 24),
          
          // Repeat days
          _buildRepeatSection(),
          const SizedBox(height: 24),
          
          // Mission selection
          _buildMissionSection(),
          const SizedBox(height: 24),
          
          // Difficulty
          _buildDifficultySection(),
          const SizedBox(height: 24),
          
          // Wake-up check
          _buildWakeUpCheckSection(),
          const SizedBox(height: 40),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAlarm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5FF),
                foregroundColor: const Color(0xFF0F0F1E),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Save Alarm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeSection() {
    return Card(
      child: InkWell(
        onTap: _pickTime,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _selectedTime.format(context),
                style: const TextStyle(
                  color: Color(0xFF00F5FF),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLabelSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _labelController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Label',
            labelStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
  
  Widget _buildRepeatSection() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Repeat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final isSelected = _repeatDays.contains(index);
                return FilterChip(
                  label: Text(days[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _repeatDays.add(index);
                      } else {
                        _repeatDays.remove(index);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF00F5FF),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF0F0F1E) : Colors.white,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMissionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wake-up Mission',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MissionType.values.map((mission) {
                final isSelected = _selectedMission == mission;
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mission.icon),
                      const SizedBox(width: 4),
                      Text(mission.displayName),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedMission = mission);
                    }
                  },
                  selectedColor: const Color(0xFF00F5FF),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF0F0F1E) : Colors.white,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDifficultySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Difficulty: $_difficulty / 5',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Slider(
              value: _difficulty.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: const Color(0xFF00F5FF),
              onChanged: (value) {
                setState(() => _difficulty = value.toInt());
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWakeUpCheckSection() {
    return Card(
      child: SwitchListTile(
        title: const Text(
          'Wake-up Verification',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: const Text(
          'Verify you\'re awake 5 minutes after dismissing',
          style: TextStyle(color: Colors.white70),
        ),
        value: _wakeUpCheck,
        onChanged: (value) {
          setState(() => _wakeUpCheck = value);
        },
        activeColor: const Color(0xFF00F5FF),
      ),
    );
  }
  
  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }
  
  void _saveAlarm() async {
    final now = DateTime.now();
    final alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    widget.alarm
      ..time = alarmTime
      ..label = _labelController.text
      ..missionType = _selectedMission
      ..missionDifficulty = _difficulty
      ..wakeUpCheckEnabled = _wakeUpCheck
      ..repeatDays = _repeatDays.toList()..sort()
      ..isEnabled = true;
    
    await AlarmService.scheduleAlarm(widget.alarm);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
  
  void _deleteAlarm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFFF3366)),
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await AlarmService.deleteAlarm(widget.alarm);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

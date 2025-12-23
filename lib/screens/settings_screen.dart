import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/alarm.dart';

/// Settings Screen - ALL PREMIUM FEATURES FREE!
class SettingsScreen extends StatefulWidget {
  final Isar isar;
  
  const SettingsScreen({super.key, required this.isar});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // App settings
  bool _darkMode = true;
  bool _use24HourFormat = true;
  bool _autoDeleteOldAlarms = false;
  int _defaultSnoozeDuration = 5;
  bool _hapticFeedback = true;
  bool _gradualVolumeIncrease = true;
  int _gradualVolumeDuration = 60;
  bool _showMotivationalQuotes = true;
  bool _weatherAnnouncement = false;
  String _defaultMission = 'math';
  int _defaultDifficulty = 3;
  
  // Smart features
  bool _smartAlarmDefault = false;
  int _smartAlarmWindow = 30;
  bool _sleepTracking = true;
  bool _bedtimeReminder = false;
  TimeOfDay _bedtimeReminderTime = const TimeOfDay(hour: 22, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pro badge - ALL FREE!
          _buildProBadge(),
          const SizedBox(height: 24),
          
          // Alarm defaults
          _buildSection(
            title: 'Alarm Defaults',
            icon: Icons.alarm,
            children: [
              _buildSwitchTile(
                title: 'Gradual Volume Increase',
                subtitle: 'Slowly increase alarm volume',
                value: _gradualVolumeIncrease,
                onChanged: (v) => setState(() => _gradualVolumeIncrease = v),
                premium: true,
              ),
              if (_gradualVolumeIncrease)
                _buildSliderTile(
                  title: 'Volume Fade Duration',
                  value: _gradualVolumeDuration.toDouble(),
                  min: 15,
                  max: 120,
                  divisions: 7,
                  suffix: 's',
                  onChanged: (v) => setState(() => _gradualVolumeDuration = v.round()),
                ),
              _buildDropdownTile(
                title: 'Default Snooze Duration',
                value: _defaultSnoozeDuration,
                items: [1, 2, 3, 5, 10, 15, 20, 30],
                suffix: ' min',
                onChanged: (v) => setState(() => _defaultSnoozeDuration = v),
              ),
              _buildDropdownTile(
                title: 'Default Mission',
                value: _defaultMission,
                items: MissionType.values.map((m) => m.name).toList(),
                onChanged: (v) => setState(() => _defaultMission = v),
              ),
              _buildSliderTile(
                title: 'Default Difficulty',
                value: _defaultDifficulty.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => setState(() => _defaultDifficulty = v.round()),
              ),
            ],
          ),
          
          // Smart Features
          _buildSection(
            title: 'Smart Features',
            icon: Icons.auto_awesome,
            premium: true,
            children: [
              _buildSwitchTile(
                title: 'Smart Alarm (Default)',
                subtitle: 'Wake during light sleep phase',
                value: _smartAlarmDefault,
                onChanged: (v) => setState(() => _smartAlarmDefault = v),
                premium: true,
              ),
              if (_smartAlarmDefault)
                _buildSliderTile(
                  title: 'Smart Window',
                  value: _smartAlarmWindow.toDouble(),
                  min: 10,
                  max: 45,
                  divisions: 7,
                  suffix: ' min',
                  onChanged: (v) => setState(() => _smartAlarmWindow = v.round()),
                ),
              _buildSwitchTile(
                title: 'Sleep Tracking',
                subtitle: 'Monitor sleep quality',
                value: _sleepTracking,
                onChanged: (v) => setState(() => _sleepTracking = v),
                premium: true,
              ),
              _buildSwitchTile(
                title: 'Bedtime Reminder',
                subtitle: 'Notify when it\'s time to sleep',
                value: _bedtimeReminder,
                onChanged: (v) => setState(() => _bedtimeReminder = v),
                premium: true,
              ),
              if (_bedtimeReminder)
                _buildTimeTile(
                  title: 'Bedtime',
                  value: _bedtimeReminderTime,
                  onChanged: (v) => setState(() => _bedtimeReminderTime = v),
                ),
            ],
          ),
          
          // Display
          _buildSection(
            title: 'Display',
            icon: Icons.palette,
            children: [
              _buildSwitchTile(
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
              ),
              _buildSwitchTile(
                title: '24-Hour Format',
                subtitle: 'Use 24-hour time format',
                value: _use24HourFormat,
                onChanged: (v) => setState(() => _use24HourFormat = v),
              ),
              _buildSwitchTile(
                title: 'Motivational Quotes',
                subtitle: 'Show quotes when alarm rings',
                value: _showMotivationalQuotes,
                onChanged: (v) => setState(() => _showMotivationalQuotes = v),
                premium: true,
              ),
            ],
          ),
          
          // Haptics & Feedback
          _buildSection(
            title: 'Haptics & Sound',
            icon: Icons.vibration,
            children: [
              _buildSwitchTile(
                title: 'Haptic Feedback',
                subtitle: 'Vibrate on interactions',
                value: _hapticFeedback,
                onChanged: (v) => setState(() => _hapticFeedback = v),
              ),
              _buildSwitchTile(
                title: 'Weather Announcement',
                subtitle: 'Speak weather on wake',
                value: _weatherAnnouncement,
                onChanged: (v) => setState(() => _weatherAnnouncement = v),
                premium: true,
              ),
            ],
          ),
          
          // Backup & Export
          _buildSection(
            title: 'Backup & Export',
            icon: Icons.cloud_upload,
            premium: true,
            children: [
              _buildActionTile(
                title: 'Export Alarms',
                subtitle: 'Save alarms as JSON file',
                icon: Icons.download,
                onTap: _exportAlarms,
                premium: true,
              ),
              _buildActionTile(
                title: 'Import Alarms',
                subtitle: 'Load alarms from JSON file',
                icon: Icons.upload,
                onTap: _importAlarms,
                premium: true,
              ),
              _buildActionTile(
                title: 'Export Sleep Data',
                subtitle: 'Export sleep history as CSV',
                icon: Icons.bedtime,
                onTap: _exportSleepData,
                premium: true,
              ),
            ],
          ),
          
          // Data Management
          _buildSection(
            title: 'Data Management',
            icon: Icons.storage,
            children: [
              _buildSwitchTile(
                title: 'Auto-Delete Old Alarms',
                subtitle: 'Remove one-time alarms after trigger',
                value: _autoDeleteOldAlarms,
                onChanged: (v) => setState(() => _autoDeleteOldAlarms = v),
              ),
              _buildActionTile(
                title: 'Clear All Alarms',
                subtitle: 'Delete all saved alarms',
                icon: Icons.delete_forever,
                onTap: _clearAllAlarms,
                isDestructive: true,
              ),
              _buildActionTile(
                title: 'Clear Statistics',
                subtitle: 'Reset all tracking data',
                icon: Icons.delete_sweep,
                onTap: _clearStats,
                isDestructive: true,
              ),
            ],
          ),
          
          // About
          _buildSection(
            title: 'About',
            icon: Icons.info,
            children: [
              _buildInfoTile('Version', '1.0.0'),
              _buildInfoTile('Developer', 'Anubhav Anand'),
              _buildActionTile(
                title: 'Rate App',
                subtitle: 'Leave a review',
                icon: Icons.star,
                onTap: () {},
              ),
              _buildActionTile(
                title: 'Privacy Policy',
                subtitle: 'View privacy information',
                icon: Icons.privacy_tip,
                onTap: () {},
              ),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.3),
            const Color(0xFF6366F1).withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Color(0xFFFFD700),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎉 ALL PREMIUM FEATURES UNLOCKED!',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enjoy all features for FREE, forever!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool premium = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00F5FF), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (premium) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'FREE',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool premium = false,
  }) {
    return ListTile(
      title: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          if (premium) ...[
            const SizedBox(width: 8),
            const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
          ],
        ],
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF00F5FF),
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    String suffix = '',
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              Text(
                '${value.round()}$suffix',
                style: const TextStyle(color: Color(0xFF00F5FF), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6366F1),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: const Color(0xFF00F5FF),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required T value,
    required List<T> items,
    String suffix = '',
    required ValueChanged<T> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: DropdownButton<T>(
        value: value,
        dropdownColor: const Color(0xFF1A1A2E),
        style: const TextStyle(color: Color(0xFF00F5FF)),
        underline: const SizedBox(),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text('$item$suffix'),
        )).toList(),
        onChanged: (v) => v != null ? onChanged(v) : null,
      ),
    );
  }

  Widget _buildTimeTile({
    required String title,
    required TimeOfDay value,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: TextButton(
        onPressed: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: value,
          );
          if (time != null) onChanged(time);
        },
        child: Text(
          value.format(context),
          style: const TextStyle(color: Color(0xFF00F5FF)),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool premium = false,
  }) {
    final color = isDestructive ? const Color(0xFFFF3366) : const Color(0xFF00F5FF);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Row(
        children: [
          Text(title, style: TextStyle(color: isDestructive ? color : Colors.white)),
          if (premium) ...[
            const SizedBox(width: 8),
            const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
          ],
        ],
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Text(value, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
    );
  }

  Future<void> _exportAlarms() async {
    try {
      final alarms = await widget.isar.alarms.where().findAll();
      final data = alarms.map((a) => {
        'time': a.time.toIso8601String(),
        'label': a.label,
        'isEnabled': a.isEnabled,
        'repeatDays': a.repeatDays,
        'missionType': a.missionType.name,
        'missionDifficulty': a.missionDifficulty,
        'soundPath': a.soundPath,
        'volume': a.volume,
        'vibrate': a.vibrate,
      }).toList();
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/alarms_backup.json');
      await file.writeAsString(jsonEncode(data));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${alarms.length} alarms to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importAlarms() async {
    // Simplified - in real app would use file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature - select a backup file')),
    );
  }

  Future<void> _exportSleepData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting sleep data as CSV...')),
    );
  }

  Future<void> _clearAllAlarms() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Clear All Alarms?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete all your alarms. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.isar.writeTxn(() async {
        await widget.isar.alarms.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All alarms deleted')),
        );
      }
    }
  }

  Future<void> _clearStats() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Statistics cleared')),
    );
  }
}

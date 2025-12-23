import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import 'alarm_edit_screen.dart';
import 'sleep_tracking_screen.dart';
import 'sleep_history_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'nap_timer_screen.dart';

class HomeScreen extends StatefulWidget {
  final Isar isar;
  
  const HomeScreen({Key? key, required this.isar}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<Alarm>> _alarmsStream;
  int _currentIndex = 0;  // 0 = Alarms, 1 = Sleep
  
  @override
  void initState() {
    super.initState();
    
    // Set up reactive stream from Isar
    _alarmsStream = widget.isar.alarms
        .where()
        .sortByTime()
        .watch(fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildCurrentTab(),
      ),
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
  
  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildAlarmsTab();
      case 1:
        return _buildSleepTab();
      case 2:
        return StatsScreen(isar: widget.isar);
      case 3:
        return SettingsScreen(isar: widget.isar);
      default:
        return _buildAlarmsTab();
    }
  }
  
  Widget? _buildFAB() {
    if (_currentIndex == 0) {
      return FloatingActionButton.extended(
        onPressed: _addNewAlarm,
        backgroundColor: const Color(0xFF00F5FF),
        foregroundColor: const Color(0xFF0F0F1E),
        icon: const Icon(Icons.add),
        label: const Text(
          'New Alarm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ).animate().scale(delay: 500.ms, curve: Curves.elasticOut);
    } else if (_currentIndex == 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nap timer FAB
          FloatingActionButton(
            heroTag: 'nap',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NapTimerScreen(isar: widget.isar)),
            ),
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: const Color(0xFF0F0F1E),
            mini: true,
            child: const Icon(Icons.timer),
          ),
          const SizedBox(height: 12),
          // Sleep tracking FAB
          FloatingActionButton.extended(
            heroTag: 'sleep',
            onPressed: _startSleepTracking,
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.bedtime),
            label: const Text(
              'Track Sleep',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ).animate().scale(delay: 500.ms, curve: Curves.elasticOut);
    }
    return null;
  }
  
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: const Color(0xFF00F5FF),
        unselectedItemColor: Colors.white.withOpacity(0.4),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Alarms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bedtime),
            label: 'Sleep',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
  
  Widget _buildAlarmsTab() {
    return Column(
      children: [
        // Header
        _buildHeader(),
        
        // Alarms list
        Expanded(
          child: StreamBuilder<List<Alarm>>(
            stream: _alarmsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              final alarms = snapshot.data!;
              
              if (alarms.isEmpty) {
                return _buildEmptyState();
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: alarms.length,
                itemBuilder: (context, index) {
                  return _buildAlarmCard(alarms[index])
                      .animate()
                      .fadeIn(delay: (100 * index).ms)
                      .slideX(begin: 0.2, end: 0);
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSleepTab() {
    return Column(
      children: [
        _buildSleepHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sleep tracking card
                _buildSleepCard(),
                const SizedBox(height: 16),
                // Quick stats
                _buildSleepStats(),
                const SizedBox(height: 16),
                // History button
                _buildHistoryButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSleepHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌙',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sleep Tracking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monitor your sleep quality',
            style: TextStyle(
              color: const Color(0xFF6366F1),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSleepCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.3),
            const Color(0xFF1A1A2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bedtime,
            size: 60,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ready to Sleep?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Place your phone on the mattress\nand tap "Track Sleep" to begin',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureChip(Icons.timeline, 'Cycles'),
              const SizedBox(width: 12),
              _buildFeatureChip(Icons.bar_chart, 'Quality'),
              const SizedBox(width: 12),
              _buildFeatureChip(Icons.history, 'History'),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }
  
  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6366F1)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSleepStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            icon: Icons.nightlight,
            label: 'Last Night',
            value: '--',
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            icon: Icons.star,
            label: 'Avg Quality',
            value: '--',
            color: const Color(0xFFFFD700),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SleepHistoryScreen(isar: widget.isar),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history,
              color: const Color(0xFF00F5FF),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sleep History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'View all your sleep records',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
  
  void _startSleepTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SleepTrackingScreen(isar: widget.isar),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⏰',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          const Text(
            'Wake Me Up Pro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unkillable Alarms',
            style: TextStyle(
              color: const Color(0xFF00F5FF),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.alarm_off,
            size: 100,
            color: Color(0xFF2A2A3E),
          ),
          const SizedBox(height: 24),
          Text(
            'No alarms yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create one',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 16,
            ),
          ),
        ],
      )
          .animate()
          .fadeIn()
          .scale(delay: 200.ms),
    );
  }
  
  Widget _buildAlarmCard(Alarm alarm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _editAlarm(alarm),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.timeString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alarm.label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          alarm.missionType.icon,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          alarm.missionType.displayName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          alarm.repeatDaysString,
                          style: TextStyle(
                            color: const Color(0xFF00F5FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Toggle switch
              Switch(
                value: alarm.isEnabled,
                onChanged: (value) async {
                  await AlarmService.toggleAlarm(alarm);
                },
                activeColor: const Color(0xFF00F5FF),
                activeTrackColor: const Color(0xFF00F5FF).withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _addNewAlarm() async {
    final now = DateTime.now();
    final defaultTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour + 1,
      0,
    );
    
    final newAlarm = Alarm.create(
      time: defaultTime,
      label: 'Wake up',
    );
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(
          alarm: newAlarm,
          isar: widget.isar,
        ),
      ),
    );
  }
  
  void _editAlarm(Alarm alarm) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(
          alarm: alarm,
          isar: widget.isar,
        ),
      ),
    );
  }
}

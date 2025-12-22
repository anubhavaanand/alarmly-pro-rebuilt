import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import 'alarm_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  final Isar isar;
  
  const HomeScreen({Key? key, required this.isar}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<Alarm>> _alarmsStream;
  
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
        child: Column(
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewAlarm,
        backgroundColor: const Color(0xFF00F5FF),
        foregroundColor: const Color(0xFF0F0F1E),
        icon: const Icon(Icons.add),
        label: const Text(
          'New Alarm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      )
          .animate()
          .scale(delay: 500.ms, curve: Curves.elasticOut),
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

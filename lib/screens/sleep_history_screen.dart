import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:isar/isar.dart';
import '../models/sleep_record.dart';

class SleepHistoryScreen extends StatefulWidget {
  final Isar isar;
  
  const SleepHistoryScreen({
    Key? key,
    required this.isar,
  }) : super(key: key);

  @override
  State<SleepHistoryScreen> createState() => _SleepHistoryScreenState();
}

class _SleepHistoryScreenState extends State<SleepHistoryScreen> {
  List<SleepRecord> _records = [];
  bool _isLoading = true;
  
  // Stats
  int _avgQuality = 0;
  int _avgDuration = 0;
  int _weeklyAvgQuality = 0;
  
  @override
  void initState() {
    super.initState();
    _loadRecords();
  }
  
  Future<void> _loadRecords() async {
    final records = await widget.isar.sleepRecords
        .where()
        .sortByBedTimeDesc()
        .findAll();
    
    // Calculate averages
    if (records.isNotEmpty) {
      int totalQuality = 0;
      int totalDuration = 0;
      
      for (final record in records) {
        totalQuality += record.sleepQuality;
        totalDuration += record.totalSleepMinutes;
      }
      
      _avgQuality = totalQuality ~/ records.length;
      _avgDuration = totalDuration ~/ records.length;
      
      // Weekly average
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final weeklyRecords = records.where(
        (r) => r.bedTime.isAfter(weekAgo)
      ).toList();
      
      if (weeklyRecords.isNotEmpty) {
        int weeklyTotal = 0;
        for (final r in weeklyRecords) {
          weeklyTotal += r.sleepQuality;
        }
        _weeklyAvgQuality = weeklyTotal ~/ weeklyRecords.length;
      }
    }
    
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sleep History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bedtime_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'No sleep records yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your sleep\nto see your history',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards
          _buildStatsRow(),
          
          const SizedBox(height: 24),
          
          // Weekly chart
          _buildWeeklyChart(),
          
          const SizedBox(height: 24),
          
          // Recent records
          const Text(
            'Recent Sleep',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...List.generate(
            _records.length.clamp(0, 30),
            (index) => _buildRecordCard(_records[index], index),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Avg Quality',
            '$_avgQuality%',
            Icons.star,
            const Color(0xFFFFD700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Avg Duration',
            '${_avgDuration ~/ 60}h ${_avgDuration % 60}m',
            Icons.schedule,
            const Color(0xFF00F5FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'This Week',
            '$_weeklyAvgQuality%',
            Icons.trending_up,
            const Color(0xFF10B981),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.2, end: 0);
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
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
              fontSize: 20,
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
  
  Widget _buildWeeklyChart() {
    // Get last 7 days of data
    final now = DateTime.now();
    final List<Map<String, dynamic>> weekData = [];
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayRecords = _records.where((r) {
        return r.bedTime.year == day.year &&
               r.bedTime.month == day.month &&
               r.bedTime.day == day.day;
      }).toList();
      
      weekData.add({
        'day': _getDayName(day),
        'quality': dayRecords.isNotEmpty ? dayRecords.first.sleepQuality : 0,
        'duration': dayRecords.isNotEmpty ? dayRecords.first.totalSleepMinutes : 0,
      });
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sleep Quality This Week',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekData.map((data) {
                final quality = data['quality'] as int;
                final heightFactor = quality / 100;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (quality > 0)
                      Text(
                        '$quality%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 30,
                      height: (120 * heightFactor).clamp(8, 120),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: quality > 0
                              ? [
                                  const Color(0xFF6366F1),
                                  const Color(0xFF00F5FF),
                                ]
                              : [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.1),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['day'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
  
  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
  
  Widget _buildRecordCard(SleepRecord record, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Quality circle
          Container(
            width: 56,
            height: 56,
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
              child: Text(
                '${record.sleepQuality}%',
                style: TextStyle(
                  color: Color(record.qualityColor),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(record.bedTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(record.bedTime)} - ${_formatTime(record.wakeTime)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Duration
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.sleepDurationString,
                style: const TextStyle(
                  color: Color(0xFF00F5FF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.qualityRating,
                style: TextStyle(
                  color: Color(record.qualityColor),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
               date.month == yesterday.month &&
               date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:isar/isar.dart';
import '../models/alarm.dart';
import '../models/alarm_stats.dart';

/// Statistics & Insights Screen - PREMIUM FEATURE (FREE!)
class StatsScreen extends StatefulWidget {
  final Isar isar;
  
  const StatsScreen({super.key, required this.isar});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<AlarmStats> _recentStats = [];
  int _totalAlarms = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  double _avgWakeDelay = 0;
  Map<String, int> _missionUsage = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    // Load recent alarm stats
    final stats = await widget.isar.alarmStats
        .where()
        .sortByDateDesc()
        .limit(100)
        .findAll();

    // Calculate aggregates
    int streak = 0;
    int bestStreak = 0;
    double totalDelay = 0;
    final missionUsage = <String, int>{};

    for (final stat in stats) {
      if (stat.dismissed) {
        streak++;
        if (streak > bestStreak) bestStreak = streak;
      } else {
        streak = 0;
      }
      
      totalDelay += stat.wakeDelay;
      missionUsage[stat.missionType] = (missionUsage[stat.missionType] ?? 0) + 1;
    }

    setState(() {
      _recentStats = stats;
      _totalAlarms = stats.length;
      _currentStreak = streak;
      _bestStreak = bestStreak;
      _avgWakeDelay = stats.isNotEmpty ? totalDelay / stats.length : 0;
      _missionUsage = missionUsage;
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
        title: const Text('Statistics & Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero stats
                  _buildHeroStats(),
                  const SizedBox(height: 24),
                  
                  // Streak card
                  _buildStreakCard(),
                  const SizedBox(height: 24),
                  
                  // Mission breakdown
                  _buildMissionBreakdown(),
                  const SizedBox(height: 24),
                  
                  // Weekly chart
                  _buildWeeklyChart(),
                  const SizedBox(height: 24),
                  
                  // Achievements
                  _buildAchievements(),
                  const SizedBox(height: 24),
                  
                  // Tips
                  _buildTips(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.alarm,
            value: '$_totalAlarms',
            label: 'Total Alarms',
            color: const Color(0xFF00F5FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer,
            value: '${_avgWakeDelay.toStringAsFixed(1)}m',
            label: 'Avg Wake Delay',
            color: const Color(0xFFFFD700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            value: '$_currentStreak',
            label: 'Current Streak',
            color: const Color(0xFFFF6B35),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
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
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withValues(alpha: 0.3),
            const Color(0xFF1A1A2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wake-Up Streak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStreakStat('Current', _currentStreak),
                    const SizedBox(width: 24),
                    _buildStreakStat('Best', _bestStreak),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1);
  }

  Widget _buildStreakStat(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        Text(
          '$value days',
          style: const TextStyle(
            color: Color(0xFFFF6B35),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMissionBreakdown() {
    final total = _missionUsage.values.fold(0, (a, b) => a + b);
    
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
            'Mission Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_missionUsage.isEmpty)
            Text(
              'No mission data yet',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            )
          else
            ..._missionUsage.entries.map((e) {
              final percentage = total > 0 ? (e.value / total) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key.isNotEmpty ? e.key : 'Unknown',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Color(0xFF00F5FF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF00F5FF)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildWeeklyChart() {
    // Simplified weekly chart
    final weekData = List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      final dayStats = _recentStats.where((s) =>
          s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day);
      return dayStats.length;
    });
    
    final maxValue = weekData.reduce((a, b) => a > b ? a : b);
    
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
            'This Week',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final day = DateTime.now().subtract(Duration(days: 6 - i));
                final heightFactor = maxValue > 0 ? weekData[i] / maxValue : 0.0;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (weekData[i] > 0)
                      Text(
                        '${weekData[i]}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: 30,
                      height: (100 * heightFactor).clamp(8, 100),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF6366F1), Color(0xFF00F5FF)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getDayName(day),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  String _getDayName(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }

  Widget _buildAchievements() {
    final achievements = [
      {'icon': '🌅', 'name': 'Early Bird', 'desc': 'Wake before 6 AM', 'unlocked': _totalAlarms > 0},
      {'icon': '🔥', 'name': 'On Fire', 'desc': '7 day streak', 'unlocked': _bestStreak >= 7},
      {'icon': '💪', 'name': 'Unstoppable', 'desc': '30 day streak', 'unlocked': _bestStreak >= 30},
      {'icon': '🧠', 'name': 'Brain Power', 'desc': 'Complete 50 math missions', 'unlocked': (_missionUsage['Math Problem'] ?? 0) >= 50},
      {'icon': '🏃', 'name': 'Active Waker', 'desc': 'Use 5 different missions', 'unlocked': _missionUsage.length >= 5},
      {'icon': '👑', 'name': 'Alarm Master', 'desc': '100 total alarms', 'unlocked': _totalAlarms >= 100},
    ];

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
            'Achievements',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((a) {
              final unlocked = a['unlocked'] as bool;
              return Container(
                width: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: unlocked 
                      ? const Color(0xFF00F5FF).withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: unlocked 
                        ? const Color(0xFF00F5FF).withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      a['icon'] as String,
                      style: TextStyle(
                        fontSize: 24,
                        color: unlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a['name'] as String,
                      style: TextStyle(
                        color: unlocked ? Colors.white : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTips() {
    final tips = [
      '💡 Consistent wake times improve sleep quality',
      '💡 Place phone away from bed to force getting up',
      '💡 Use harder missions on weekdays',
      '💡 Enable Smart Alarm for gentle waking',
    ];

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
            'Tips for Better Waking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          )),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  void _shareStats() {
    // Share stats functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stats sharing coming soon!')),
    );
  }
}

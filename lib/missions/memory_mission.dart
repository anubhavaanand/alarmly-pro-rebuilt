import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MemoryMission extends StatefulWidget {
  final int difficulty; // 1-5
  final VoidCallback onComplete;
  
  const MemoryMission({
    Key? key,
    required this.difficulty,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<MemoryMission> createState() => _MemoryMissionState();
}

class _MemoryMissionState extends State<MemoryMission> {
  late List<MemoryCard> _cards;
  int? _firstCardIndex;
  int? _secondCardIndex;
  int _matchesFound = 0;
  int _totalPairs = 0;
  bool _isProcessing = false;
  int _attempts = 0;
  
  // Emojis for card matching
  static const List<String> _allEmojis = [
    '🌟', '🔥', '💎', '🎯', '🚀', '⚡', '🌈', '🎪',
    '🦄', '🌸', '🍀', '🎵', '🎨', '🌙', '🦋', '🍭',
    '🎲', '🎸', '🌺', '🍉', '🦊', '🐬', '🌻', '🎁',
  ];
  
  @override
  void initState() {
    super.initState();
    _setupGame();
  }
  
  void _setupGame() {
    // Pairs based on difficulty (2-6 pairs)
    _totalPairs = widget.difficulty + 1;
    final random = Random();
    
    // Select random emojis for this game
    final shuffledEmojis = List<String>.from(_allEmojis)..shuffle(random);
    final selectedEmojis = shuffledEmojis.take(_totalPairs).toList();
    
    // Create pairs
    _cards = [];
    for (int i = 0; i < _totalPairs; i++) {
      _cards.add(MemoryCard(emoji: selectedEmojis[i], pairId: i));
      _cards.add(MemoryCard(emoji: selectedEmojis[i], pairId: i));
    }
    
    // Shuffle cards
    _cards.shuffle(random);
  }
  
  void _onCardTap(int index) {
    if (_isProcessing) return;
    if (_cards[index].isMatched) return;
    if (_cards[index].isFlipped) return;
    
    setState(() {
      _cards[index].isFlipped = true;
      
      if (_firstCardIndex == null) {
        _firstCardIndex = index;
      } else {
        _secondCardIndex = index;
        _isProcessing = true;
        _attempts++;
        _checkMatch();
      }
    });
  }
  
  void _checkMatch() async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return;
    
    final first = _cards[_firstCardIndex!];
    final second = _cards[_secondCardIndex!];
    
    if (first.pairId == second.pairId) {
      // Match found!
      setState(() {
        first.isMatched = true;
        second.isMatched = true;
        _matchesFound++;
      });
      
      // Check if game complete
      if (_matchesFound == _totalPairs) {
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onComplete();
      }
    } else {
      // No match, flip back
      setState(() {
        first.isFlipped = false;
        second.isFlipped = false;
      });
    }
    
    setState(() {
      _firstCardIndex = null;
      _secondCardIndex = null;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate grid columns based on total cards
    int crossAxisCount = _cards.length <= 8 ? 2 : (_cards.length <= 12 ? 3 : 4);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              const SizedBox(height: 16),
              const Text(
                '🧠 Memory Match',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Find all $_totalPairs matching pairs',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatCard('Matched', '$_matchesFound / $_totalPairs'),
                  const SizedBox(width: 16),
                  _buildStatCard('Attempts', '$_attempts'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _matchesFound / _totalPairs,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(
                      const Color(0xFFFF00FF),
                      const Color(0xFF00FF88),
                      _matchesFound / _totalPairs,
                    )!,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Card grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    return _buildCard(index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00F5FF),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
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
  
  Widget _buildCard(int index) {
    final card = _cards[index];
    
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: card.isMatched
                ? [const Color(0xFF00FF88), const Color(0xFF00DD66)]
                : card.isFlipped
                    ? [const Color(0xFF00F5FF), const Color(0xFF0088FF)]
                    : [const Color(0xFF2A2A4E), const Color(0xFF1E1E3E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (card.isFlipped || card.isMatched)
              BoxShadow(
                color: card.isMatched
                    ? const Color(0xFF00FF88).withOpacity(0.3)
                    : const Color(0xFF00F5FF).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: card.isFlipped || card.isMatched
                ? Text(
                    card.emoji,
                    key: ValueKey(card.emoji),
                    style: const TextStyle(fontSize: 40),
                  )
                    .animate()
                    .scale(duration: 200.ms, curve: Curves.easeOut)
                : const Icon(
                    Icons.help_outline,
                    key: ValueKey('hidden'),
                    color: Colors.white24,
                    size: 40,
                  ),
          ),
        ),
      ),
    )
        .animate(delay: (50 * index).ms)
        .fadeIn()
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }
}

class MemoryCard {
  final String emoji;
  final int pairId;
  bool isFlipped;
  bool isMatched;
  
  MemoryCard({
    required this.emoji,
    required this.pairId,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

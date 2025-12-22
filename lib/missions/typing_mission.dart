import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TypingMission extends StatefulWidget {
  final int difficulty; // 1-5
  final VoidCallback onComplete;
  
  const TypingMission({
    Key? key,
    required this.difficulty,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<TypingMission> createState() => _TypingMissionState();
}

class _TypingMissionState extends State<TypingMission> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  late String _targetSentence;
  late int _sentencesRequired;
  int _sentencesCompleted = 0;
  bool _showError = false;
  bool _showSuccess = false;
  
  // Sentences by difficulty
  static const _easySentences = [
    'Good morning sunshine',
    'Wake up and smile',
    'Today is a new day',
    'Rise and shine now',
    'Time to get up',
  ];
  
  static const _mediumSentences = [
    'The early bird catches the worm',
    'Every day is a fresh start',
    'Make today absolutely amazing',
    'Opportunities await the awake',
    'Seize the day with energy',
  ];
  
  static const _hardSentences = [
    'Success comes to those who wake up early',
    'The greatest glory is rising every day',
    'Your future is created by what you do today',
    'Dream big, wake up, and make it happen',
    'A journey of a thousand miles begins now',
  ];
  
  static const _veryHardSentences = [
    'The difference between ordinary and extraordinary is that little extra effort',
    'Life is what happens when you are busy making other plans, so wake up',
    'Do not wait for opportunity, create it by starting your day with purpose',
  ];
  
  static const _extremeSentences = [
    'In the middle of difficulty lies opportunity, embrace it with open eyes today',
    'Yesterday is history, tomorrow is a mystery, but today is a gift, that is why it is called present',
    'The only way to do great work is to love what you do and start doing it right now',
  ];
  
  @override
  void initState() {
    super.initState();
    _sentencesRequired = (widget.difficulty / 2).ceil();
    _generateSentence();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _generateSentence() {
    final random = Random();
    List<String> sentences;
    
    switch (widget.difficulty) {
      case 1:
        sentences = _easySentences;
        break;
      case 2:
        sentences = _mediumSentences;
        break;
      case 3:
        sentences = _hardSentences;
        break;
      case 4:
        sentences = _veryHardSentences;
        break;
      case 5:
      default:
        sentences = _extremeSentences;
        break;
    }
    
    _targetSentence = sentences[random.nextInt(sentences.length)];
  }
  
  void _checkInput() {
    final input = _controller.text.trim();
    final target = _targetSentence.trim();
    
    // Case-insensitive comparison
    if (input.toLowerCase() == target.toLowerCase()) {
      setState(() {
        _showSuccess = true;
        _sentencesCompleted++;
      });
      
      if (_sentencesCompleted >= _sentencesRequired) {
        // Mission complete
        Future.delayed(const Duration(milliseconds: 800), () {
          widget.onComplete();
        });
      } else {
        // Next sentence
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _showSuccess = false;
              _controller.clear();
              _generateSentence();
            });
          }
        });
      }
    } else {
      // Wrong input
      setState(() => _showError = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showError = false);
        }
      });
    }
  }
  
  double get _typingAccuracy {
    final input = _controller.text.toLowerCase();
    final target = _targetSentence.toLowerCase();
    
    if (input.isEmpty) return 0;
    
    int correct = 0;
    for (int i = 0; i < input.length && i < target.length; i++) {
      if (input[i] == target[i]) correct++;
    }
    
    return correct / target.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              const Text(
                '⌨️ Type to Wake Up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate()
                  .fadeIn()
                  .slideY(begin: -0.3, end: 0),
              
              const SizedBox(height: 8),
              
              Text(
                'Sentence ${_sentencesCompleted + 1} of $_sentencesRequired',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Target sentence card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _showSuccess
                        ? [const Color(0xFF00FF88), const Color(0xFF00DD66)]
                        : _showError
                            ? [const Color(0xFFFF3366), const Color(0xFFFF5588)]
                            : [const Color(0xFF1A1A2E), const Color(0xFF2A2A3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _showSuccess
                          ? const Color(0xFF00FF88).withOpacity(0.3)
                          : _showError
                              ? const Color(0xFFFF3366).withOpacity(0.3)
                              : Colors.transparent,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Type this sentence:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _targetSentence,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  .animate(target: _showError ? 1 : 0)
                  .shake(duration: 500.ms, hz: 4),
              
              const SizedBox(height: 32),
              
              // Accuracy indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Accuracy: ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${(_typingAccuracy * 100).toInt()}%',
                    style: TextStyle(
                      color: Color.lerp(
                        const Color(0xFFFF3366),
                        const Color(0xFF00FF88),
                        _typingAccuracy,
                      ),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Input field
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: 'Start typing here...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _checkInput(),
              ),
              
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checkInput,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5FF),
                    foregroundColor: const Color(0xFF0F0F1E),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              if (_showSuccess) ...[
                const SizedBox(height: 24),
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00FF88),
                  size: 64,
                )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.elasticOut),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

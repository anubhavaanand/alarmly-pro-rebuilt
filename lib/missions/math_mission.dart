import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MathMission extends StatefulWidget {
  final int difficulty; // 1-5
  final VoidCallback onComplete;
  
  const MathMission({
    Key? key,
    required this.difficulty,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<MathMission> createState() => _MathMissionState();
}

class _MathMissionState extends State<MathMission> {
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  late int _num1, _num2, _num3, _correctAnswer;
  late String _operation;
  int _problemsSolved = 0;
  int _problemsRequired = 1;
  bool _isCorrect = false;
  bool _showError = false;
  
  @override
  void initState() {
    super.initState();
    _problemsRequired = _calculateProblemsRequired();
    _generateProblem();
    
    // Auto-focus input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  int _calculateProblemsRequired() {
    // Difficulty 1: 1 problem, Difficulty 5: 3 problems
    return (widget.difficulty / 2).ceil();
  }
  
  void _generateProblem() {
    final random = Random();
    
    switch (widget.difficulty) {
      case 1: // Easy: Single-digit addition
        _num1 = random.nextInt(9) + 1;
        _num2 = random.nextInt(9) + 1;
        _correctAnswer = _num1 + _num2;
        _operation = '$_num1 + $_num2';
        break;
        
      case 2: // Medium: Two-digit addition/subtraction
        _num1 = random.nextInt(50) + 10;
        _num2 = random.nextInt(30) + 5;
        final isAddition = random.nextBool();
        if (isAddition) {
          _correctAnswer = _num1 + _num2;
          _operation = '$_num1 + $_num2';
        } else {
          _correctAnswer = _num1 - _num2;
          _operation = '$_num1 - $_num2';
        }
        break;
        
      case 3: // Hard: Simple multiplication
        _num1 = random.nextInt(12) + 2;
        _num2 = random.nextInt(12) + 2;
        _correctAnswer = _num1 * _num2;
        _operation = '$_num1 × $_num2';
        break;
        
      case 4: // Very Hard: Multi-step
        _num1 = random.nextInt(20) + 10;
        _num2 = random.nextInt(15) + 5;
        _num3 = random.nextInt(10) + 5;
        _correctAnswer = (_num1 + _num2) * _num3;
        _operation = '($_num1 + $_num2) × $_num3';
        break;
        
      case 5: // Extreme: Complex multi-step
        _num1 = random.nextInt(50) + 10;
        _num2 = random.nextInt(50) + 10;
        _num3 = random.nextInt(20) + 5;
        final temp = _num1 * _num2;
        _correctAnswer = temp + _num3;
        _operation = '($_num1 × $_num2) + $_num3';
        break;
        
      default:
        _generateProblem();
    }
  }
  
  void _checkAnswer() {
    final userAnswer = int.tryParse(_answerController.text);
    
    if (userAnswer == null) {
      setState(() => _showError = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _showError = false);
      });
      return;
    }
    
    if (userAnswer == _correctAnswer) {
      setState(() {
        _isCorrect = true;
        _problemsSolved++;
      });
      
      if (_problemsSolved >= _problemsRequired) {
        // Mission complete!
        Future.delayed(const Duration(milliseconds: 800), () {
          widget.onComplete();
        });
      } else {
        // Next problem
        Future.delayed(const Duration(milliseconds: 1000), () {
          setState(() {
            _isCorrect = false;
            _answerController.clear();
            _generateProblem();
          });
        });
      }
    } else {
      // Wrong answer - shake and show error
      setState(() => _showError = true);
      _answerController.clear();
      
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _showError = false);
      });
    }
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
              // Progress indicator
              Text(
                'Problem $_problemsSolved / $_problemsRequired',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              
              // Math problem
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isCorrect
                        ? [const Color(0xFF00FF88), const Color(0xFF00DD66)]
                        : _showError
                            ? [const Color(0xFFFF3366), const Color(0xFFFF5588)]
                            : [const Color(0xFF1A1A2E), const Color(0xFF2A2A3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _isCorrect
                          ? const Color(0xFF00FF88).withOpacity(0.3)
                          : _showError
                              ? const Color(0xFFFF3366).withOpacity(0.3)
                              : Colors.transparent,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Text(
                  _operation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
                  .animate(target: _showError ? 1 : 0)
                  .shake(duration: 500.ms, hz: 4),
              
              const SizedBox(height: 60),
              
              // Answer input
              TextField(
                controller: _answerController,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Your answer',
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
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
                onSubmitted: (_) => _checkAnswer(),
              ),
              
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checkAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5FF),
                    foregroundColor: const Color(0xFF0F0F1E),
                    padding: const EdgeInsets.symmetric(vertical: 20),
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
              
              if (_isCorrect) ...[
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

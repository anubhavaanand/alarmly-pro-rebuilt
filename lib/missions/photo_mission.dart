import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PhotoMission extends StatefulWidget {
  final int difficulty; // 1-5
  final VoidCallback onComplete;
  
  const PhotoMission({
    Key? key,
    required this.difficulty,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<PhotoMission> createState() => _PhotoMissionState();
}

class _PhotoMissionState extends State<PhotoMission> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isTakingPhoto = false;
  bool _showSuccess = false;
  int _photosTaken = 0;
  late int _photosRequired;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _photosRequired = widget.difficulty; // 1-5 photos based on difficulty
    _initCamera();
  }
  
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
        });
        return;
      }
      
      // Use front camera if available (selfie), otherwise back camera
      final cameraIndex = _cameras!.length > 1 ? 1 : 0;
      
      _controller = CameraController(
        _cameras![cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Camera error: $e';
      });
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isTakingPhoto) return;
    
    setState(() {
      _isTakingPhoto = true;
    });
    
    try {
      // Take the photo (we don't need to save it, just the action matters)
      await _controller!.takePicture();
      
      setState(() {
        _photosTaken++;
        _isTakingPhoto = false;
      });
      
      if (_photosTaken >= _photosRequired) {
        setState(() {
          _showSuccess = true;
        });
        
        await Future.delayed(const Duration(milliseconds: 800));
        widget.onComplete();
      }
    } catch (e) {
      setState(() {
        _isTakingPhoto = false;
        _errorMessage = 'Failed to take photo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    if (!_isInitialized) {
      return _buildLoadingState();
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    '📸 Take a Selfie',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Photo $_photosTaken of $_photosRequired',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _photosTaken / _photosRequired,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(
                          const Color(0xFFFF00FF),
                          const Color(0xFF00FF88),
                          _photosTaken / _photosRequired,
                        )!,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Camera preview
            Expanded(
              child: Stack(
                children: [
                  // Camera preview
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _showSuccess
                            ? const Color(0xFF00FF88)
                            : const Color(0xFF00F5FF),
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: CameraPreview(_controller!),
                    ),
                  ),
                  
                  // Success overlay
                  if (_showSuccess)
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF88).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle,
                            color: Color(0xFF00FF88),
                            size: 100,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(),
                    ),
                ],
              ),
            ),
            
            // Capture button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F5FF),
                      width: 4,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isTakingPhoto
                          ? const Color(0xFFFF00FF)
                          : const Color(0xFF00F5FF),
                    ),
                    child: _isTakingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF0F0F1E),
                            size: 36,
                          ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.05, 1.05),
                      duration: 1000.ms,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF00F5FF),
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing camera...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFFF3366),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Fallback: complete mission anyway
                widget.onComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5FF),
                foregroundColor: const Color(0xFF0F0F1E),
              ),
              child: const Text('Skip Mission'),
            ),
          ],
        ),
      ),
    );
  }
}

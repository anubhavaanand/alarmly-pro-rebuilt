import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BarcodeMission extends StatefulWidget {
  final int difficulty; // 1-5
  final VoidCallback onComplete;
  final String? registeredBarcode; // Pass from alarm settings
  
  const BarcodeMission({
    Key? key,
    required this.difficulty,
    required this.onComplete,
    this.registeredBarcode,
  }) : super(key: key);

  @override
  State<BarcodeMission> createState() => _BarcodeMissionState();
}

class _BarcodeMissionState extends State<BarcodeMission> {
  MobileScannerController? _controller;
  String? _targetBarcode;
  String? _scannedBarcode;
  bool _isScanning = true;
  bool _showSuccess = false;
  bool _showError = false;
  bool _isRegistrationMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadTargetBarcode();
    _initScanner();
  }
  
  void _initScanner() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }
  
  Future<void> _loadTargetBarcode() async {
    if (widget.registeredBarcode != null) {
      _targetBarcode = widget.registeredBarcode;
      return;
    }
    
    // Try to load from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final savedBarcode = prefs.getString('registered_barcode');
    
    if (savedBarcode != null) {
      setState(() {
        _targetBarcode = savedBarcode;
      });
    } else {
      // No barcode registered, go into registration mode
      setState(() {
        _isRegistrationMode = true;
      });
    }
  }
  
  Future<void> _saveBarcode(String barcode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('registered_barcode', barcode);
  }
  
  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code == null) continue;
      
      setState(() {
        _scannedBarcode = code;
        _isScanning = false;
      });
      
      if (_isRegistrationMode) {
        _registerBarcode(code);
      } else {
        _verifyBarcode(code);
      }
      
      break;
    }
  }
  
  void _registerBarcode(String code) async {
    await _saveBarcode(code);
    
    setState(() {
      _targetBarcode = code;
      _isRegistrationMode = false;
      _showSuccess = true;
    });
    
    // Immediately complete after registration
    await Future.delayed(const Duration(milliseconds: 1000));
    widget.onComplete();
  }
  
  void _verifyBarcode(String code) async {
    if (code == _targetBarcode) {
      // Match!
      setState(() {
        _showSuccess = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 800));
      widget.onComplete();
    } else {
      // Wrong barcode
      setState(() {
        _showError = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        setState(() {
          _showError = false;
          _scannedBarcode = null;
          _isScanning = true;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    _isRegistrationMode ? '📷 Register Barcode' : '📷 Scan Barcode',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    _isRegistrationMode 
                        ? 'Scan a barcode to register it for future alarms'
                        : 'Scan the registered barcode to dismiss',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Camera preview
            Expanded(
              child: Stack(
                children: [
                  // Camera
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _showSuccess
                              ? const Color(0xFF00FF88)
                              : _showError
                                  ? const Color(0xFFFF3366)
                                  : const Color(0xFF00F5FF),
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: _controller != null
                            ? MobileScanner(
                                controller: _controller!,
                                onDetect: _onBarcodeDetected,
                              )
                            : const Center(
                                child: CircularProgressIndicator(),
                              ),
                      ),
                    ),
                  ),
                  
                  // Scanning overlay
                  if (_isScanning)
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        child: Center(
                          child: Container(
                            width: 250,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF00F5FF),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .shimmer(duration: 2000.ms),
                        ),
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
                  
                  // Error overlay
                  if (_showError)
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3366).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.close,
                                color: Color(0xFFFF3366),
                                size: 80,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Wrong barcode!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Scan the registered barcode',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .shake(duration: 500.ms),
                    ),
                ],
              ),
            ),
            
            // Footer info
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (_scannedBarcode != null && !_showSuccess)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.qr_code,
                            color: Color(0xFF00F5FF),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Scanned: $_scannedBarcode',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (_targetBarcode != null && !_isRegistrationMode) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Target: ${_targetBarcode!.substring(0, _targetBarcode!.length > 20 ? 20 : _targetBarcode!.length)}...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Torch toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => _controller?.toggleTorch(),
                        icon: const Icon(Icons.flashlight_on),
                        color: const Color(0xFF00F5FF),
                        iconSize: 32,
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: () => _controller?.switchCamera(),
                        icon: const Icon(Icons.cameraswitch),
                        color: const Color(0xFF00F5FF),
                        iconSize: 32,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

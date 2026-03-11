import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/widgets.dart';
import '../providers/camera_provider.dart';
import '../providers/food_provider.dart';
import '../services/gemini_live_service.dart';
import '../models/food_item.dart';
import 'analysis_screen.dart';
import 'pro_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final GeminiLiveService _liveService = GeminiLiveService();
  bool _isLiveMode = false;
  bool _isListening = false;
  bool _isProcessingLive = false;
  String _liveStatus = "Press and hold to ask Calx";
  final SpeechToText _stt = SpeechToText();
  late CameraProvider _cameraProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cameraProvider = Provider.of<CameraProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _liveService.requestPermissions(); // Ensure permissions are granted
      if (mounted) {
        Provider.of<CameraProvider>(context, listen: false).initializeCamera();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Explicitly turn off flash before disposing
    _cameraProvider.controller?.setFlashMode(FlashMode.off);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _cameraProvider.controller?.setFlashMode(FlashMode.off);
    }
  }

  void _showProLimitDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("PRO Required"),
        content: Text(
          "You've reached your daily limit of 3 $feature as a free user. Upgrade to PRO for unlimited access!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe Later"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF673AB7),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProScreen()),
              );
            },
            child: const Text(
              "Upgrade to PRO",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = Provider.of<CameraProvider>(context);

    if (cameraProvider.controller == null ||
        !cameraProvider.controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF673AB7)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Full Screen Camera
          Positioned.fill(child: CameraPreview(cameraProvider.controller!)),

          if (_isLiveMode) _buildLiveOverlay(),

          // Shutter Button / Live Action button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Normal Shutter (Hidden if live mode)
                if (!_isLiveMode) _buildShutterButton(cameraProvider),

                // Gemini Live Talk (Large button if live)
                if (_isLiveMode) _buildLiveMicButton(cameraProvider),
              ],
            ),
          ),

          // Live Mode Toggle (Bottom Right)
          if (!_isLiveMode)
            Positioned(
              bottom: 60,
              right: 25,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final foodProvider = Provider.of<FoodProvider>(
                    context,
                    listen: false,
                  );
                  if (!foodProvider.canUseLiveAI()) {
                    _showProLimitDialog("Live AI Sessions");
                    return;
                  }

                  final hasPerm = await _liveService.requestPermissions();
                  if (hasPerm) {
                    setState(() {
                      _isLiveMode = true;
                      _liveStatus = "Hold the mic to ask me anything";
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: const Color(0xFF673AB7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text("Live AI"),
              ),
            ),
          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              style: IconButton.styleFrom(backgroundColor: Colors.black26),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShutterButton(CameraProvider provider) {
    return GestureDetector(
      onTap: () async {
        final foodProvider = Provider.of<FoodProvider>(context, listen: false);
        if (!foodProvider.canUseImageAnalysis()) {
          _showProLimitDialog("Food Image Analyses");
          return;
        }

        final XFile? image = await provider.takePhoto();
        if (!mounted || image == null) return;

        // Increment usage
        await foodProvider.incrementImageAnalysis();
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisScreen(imagePath: image.path),
          ),
        );
      },
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF673AB7),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF673AB7).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.camera_alt, color: Colors.black, size: 40),
      ),
    );
  }

  Widget _buildLiveMicButton(CameraProvider provider) {
    return GestureDetector(
      onLongPressStart: (_) => _startLiveTalk(provider),
      onLongPressEnd: (_) => _stopAndQueryGemini(provider),
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: _isListening ? Colors.redAccent : const Color(0xFF673AB7),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isListening ? Colors.redAccent : const Color(0xFF673AB7))
                  .withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Icon(
          _isProcessingLive ? Icons.hourglass_top : Icons.mic,
          color: Colors.black,
          size: 50,
        ),
      ),
    );
  }

  Widget _buildLiveOverlay() {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF673AB7), width: 1.5),
            ),
            child: Text(
              _liveStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          IconButton(
            onPressed: () => setState(() => _isLiveMode = false),
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  void _startLiveTalk(CameraProvider provider) async {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    if (!foodProvider.canUseLiveAI()) {
      _showProLimitDialog("Live AI Queries");
      return;
    }

    await _liveService.stopSpeaking();
    final bool available = await _liveService.initSpeech();
    if (available) {
      setState(() {
        _isListening = true;
        _liveStatus = "Listening...";
      });
      _stt.listen(
        onResult: (result) {
          // We handle query on LongPressEnd
        },
      );
    }
  }

  void _stopAndQueryGemini(CameraProvider provider) async {
    if (!_isListening) return; // Case where start failed (e.g. limit reached)

    final userQuestion = _stt.lastRecognizedWords;
    _stt.stop();
    setState(() {
      _isListening = false;
      _isProcessingLive = true;
      _liveStatus = "Processing with Calx...";
    });
    _liveService.speak("Please wait a second.");

    final XFile? image = await provider.takePhoto();
    if (image == null) {
      setState(() {
        _isProcessingLive = false;
        _liveStatus = "Failed to capture frame";
      });
      return;
    }

    // Increment usage
    if (!mounted) return;
    Provider.of<FoodProvider>(context, listen: false).incrementLiveAI();

    final responseStr = await _liveService.askGemini(
      File(image.path),
      userQuestion.isEmpty ? "What's in this image?" : userQuestion,
    );

    if (mounted) {
      try {
        final decoded = jsonDecode(responseStr);
        final String text = decoded['text'] ?? "I'm not sure.";
        final String type = decoded['type'] ?? "talk";

        if (type == "log" && decoded['food_log'] != null) {
          final foodLog = FoodLog.fromJson(
            Map<String, dynamic>.from(decoded['food_log'])
              ..['timestamp'] = DateTime.now().toIso8601String()
              ..['image_path'] = image.path,
          );
          Provider.of<FoodProvider>(context, listen: false).addLog(foodLog);

          setState(() {
            _isProcessingLive = false;
            _liveStatus = "✅ Logged: $text";
          });
        } else {
          setState(() {
            _isProcessingLive = false;
            _liveStatus = text;
          });
        }
        _liveService.speak(text);
      } catch (e) {
        setState(() {
          _isProcessingLive = false;
          _liveStatus = "Captured and saved locally.";
        });
      }
    }
  }
}

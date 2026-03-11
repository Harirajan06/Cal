import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraProvider with ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  XFile? _lastImage;

  CameraController? get controller => _controller;
  XFile? get lastImage => _lastImage;

  Future<void> initializeCamera() async {
    if (_controller != null) return;
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: true, // Audio needed for Live AI
          imageFormatGroup:
              ImageFormatGroup.jpeg, // More stable for image analysis
        );
        await _controller!.initialize();
        await _controller!.setFlashMode(FlashMode.off);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<XFile?> takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    try {
      // Force flash off every time before taking a picture
      await _controller!.setFlashMode(FlashMode.off);
      _lastImage = await _controller!.takePicture();
      return _lastImage;
    } catch (e) {
      debugPrint("Take Photo Error: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

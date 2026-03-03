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
          enableAudio: false,
        );
        await _controller!.initialize();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<XFile?> takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    try {
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

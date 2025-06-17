// services/camera_service.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';


class CameraService {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;

  CameraController get cameraController => _cameraController;

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();

    _cameraController = CameraController(
      _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      ),
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController.initialize();
  }

  Future<XFile?> takePicture() async {
    if (!_cameraController.value.isInitialized) {
      return null;
    }

    if (_cameraController.value.isTakingPicture) return null;

    try {
      return await _cameraController.takePicture();
    } on StateError catch (e) {
      // When the camera controller is not in the correct state (e.g. not
      // initialized or currently taking another picture) the camera plugin
      // throws a StateError via the checkState() function. Catch it here to
      // avoid crashing and simply return null so the caller can handle it.
      debugPrint('Estado incorrecto al tomar la foto: $e');
      return null;
    } catch (e) {
      debugPrint('Error al tomar la foto: $e');
      return null;
    }
  }

  void disposeCamera() {
    _cameraController.dispose();
  }
}
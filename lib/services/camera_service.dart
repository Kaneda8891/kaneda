// services/camera_service.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;

  CameraController get cameraController => _cameraController;

  Future<bool> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('No se encontraron cámaras disponibles');
        return false;
      }

      _cameraController = CameraController(
        _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        ),
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController.initialize();
      return true;
    } on CameraException catch (e) {
      debugPrint('Error al inicializar la cámara: $e');
      return false;
    } catch (e) {
      debugPrint('Error desconocido al inicializar la cámara: $e');
      return false;
    }
  }

  Future<XFile?> takePicture() async {
    if (!_cameraController.value.isInitialized) {
      debugPrint('La cámara aún no está inicializada');
      return null;
    }

    if (_cameraController.value.isTakingPicture) {
      debugPrint('La cámara ya está tomando una foto');
      return null;
    }

    try {
      return await _cameraController.takePicture();
      } on CameraException catch (e) {
      debugPrint('Error de cámara al tomar la foto: $e');
      return null;
    } on StateError catch (e) {
      // When the camera controller is not in the correct state (e.g. not
      // initialized or currently taking another picture) the camera plugin
      // throws a StateError via the checkState() function. Catch it here to
      // avoid crashing and simply return null so the caller can handle it.

      // El plugin lanza StateError cuando la cámara no está en el estado correcto.
      debugPrint('Estado incorrecto al tomar la foto: $e');
      return null;
    } catch (e) {
      debugPrint('Error desconocido al tomar la foto: $e');
      return null;
    }
  }

  void disposeCamera() {
    _cameraController.dispose();
  }
}

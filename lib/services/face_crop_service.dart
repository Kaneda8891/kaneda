import 'dart:ui';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceCropService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  /// Detecta y recorta el rostro de una imagen JPEG desde bytes
  Future<img.Image?> detectAndCropFace(Uint8List inputImageBytes) async {
    final inputImage = InputImage.fromBytes(
      bytes: inputImageBytes,
      metadata: InputImageMetadata(
        size: const Size(720, 1280), // Estimado o real (según cámara)
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.bgra8888, // o .nv21 si usas cámara en stream
        bytesPerRow: 720 * 4, // 4 bytes por pixel para bgra8888
      ),
    );

    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return null;

    final img.Image? original = img.decodeImage(inputImageBytes);
    if (original == null) return null;

    final faceBox = faces.first.boundingBox;

    final int x = faceBox.left.toInt().clamp(0, original.width - 1);
    final int y = faceBox.top.toInt().clamp(0, original.height - 1);
    final int w = faceBox.width.toInt().clamp(1, original.width - x);
    final int h = faceBox.height.toInt().clamp(1, original.height - y);

    return img.copyCrop(original, x: x, y: y, width: w, height: h);
  }

  void dispose() {
    _faceDetector.close();
  }
}

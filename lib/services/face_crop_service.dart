import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceCropService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
    ),
  );

  /// Detecta y recorta el rostro de una imagen [inputImageBytes]
  Future<img.Image?> detectAndCropFace(Uint8List inputImageBytes) async {
    final inputImage = InputImage.fromBytes(
      bytes: inputImageBytes,
      inputImageData: InputImageData(
        size: const Size(480, 640), // ajustar al tamaño real de la imagen
        imageRotation: InputImageRotation.rotation0deg,
        inputImageFormat: InputImageFormat.nv21,
        planeData: [], // se puede dejar vacío para JPG
      ),
    );

    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) return null;

    final face = faces.first.boundingBox;
    final image = img.decodeImage(inputImageBytes);
    if (image == null) return null;

    final cropped = img.copyCrop(
      image,
      x: face.left.toInt(),
      y: face.top.toInt(),
      width: face.width.toInt(),
      height: face.height.toInt(),
    );

    return cropped;
  }

  void dispose() {
    _faceDetector.close();
  }
}

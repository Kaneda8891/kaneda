// services/face_recognition_service.dart

import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceRecognitionService {
  late Interpreter _interpreter;

  /// Carga el modelo MobileFaceNet
  Future<void> loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('assets/tflite/mobilefacenet.tflite');
  }
  
  /// Realiza la predicción del embedding facial
  Future<List<double>> predict(img.Image faceImage) async {
    final resized = img.copyResize(faceImage, width: 112, height: 112);
    final Float32List input = imageToFloat32(resized);
    final List<List<double>> output = List.generate(1, (_) => List.filled(192, 0.0));

    _interpreter.run(input.buffer.asFloat32List(), output);
    return output[0];
  }

  /// Convierte imagen en Float32List normalizado (-1 a 1)
  Float32List imageToFloat32(img.Image image) {
    final Float32List convertedBytes = Float32List(112 * 112 * 3);
    int pixelIndex = 0;

    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = image.getPixel(x, y);

        convertedBytes[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        convertedBytes[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        convertedBytes[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }

    return convertedBytes;
  }

  void dispose() {
    _interpreter.close();
  }
}

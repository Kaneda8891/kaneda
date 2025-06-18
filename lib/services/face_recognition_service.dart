// services/face_recognition_service.dart

import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceRecognitionService {
  late Interpreter _interpreter;

  /// Carga el modelo MobileFaceNet desde assets
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/tflite/mobilefacenet.tflite');
  }

  /// Realiza la predicción del embedding facial
  /// a partir de una imagen tipo img.Image (ya cargada y decodificada).
  Future<List<double>> predict(img.Image faceImage) async {
    // Redimensiona la imagen al tamaño requerido por el modelo (112x112)
    final resized = img.copyResize(faceImage, width: 112, height: 112);

    // Convierte la imagen en un arreglo plano Float32List
    final Float32List input = imageToFloat32(resized);

    // Crea una lista de salida de 192 elementos (embedding)
    final List<List<double>> output = List.generate(1, (_) => List.filled(192, 0.0));

    // Ejecuta el modelo. La entrada debe estar en el formato: [1, 112, 112, 3]
    _interpreter.run(input.reshape([1, 112, 112, 3]), output);

    return output[0];
  }

  /// Convierte la imagen en Float32List normalizado entre -1 y 1
  Float32List imageToFloat32(img.Image image) {
    final Float32List convertedBytes = Float32List(112 * 112 * 3);
    int pixelIndex = 0;

    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = image.getPixel(x, y);

        // Normaliza los valores RGB a rango [-1, 1]
        convertedBytes[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        convertedBytes[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        convertedBytes[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }

    return convertedBytes;
  }

  /// Libera el modelo cuando ya no se necesita
  void dispose() {
    _interpreter.close();
  }
}

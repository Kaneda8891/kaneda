import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceRecognitionService {
  late Interpreter _interpreter;

  /// 🔢 Tamaño esperado por el modelo
  static const int modelInputSize = 112;

  /// Carga el modelo MobileFaceNet
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/tflite/mobilefacenet.tflite');
  }

  /// Genera un embedding a partir de una imagen facial
  Future<List<double>> predict(img.Image faceImage) async {
    final resized = img.copyResize(faceImage, width: modelInputSize, height: modelInputSize);
    final Float32List input = imageToFloat32(resized);
    final List<List<double>> output = List.generate(1, (_) => List.filled(192, 0.0));

    _interpreter.run(input.reshape([1, modelInputSize, modelInputSize, 3]), output);
    return output[0];
  }

  /// Genera múltiples embeddings simulando ligeras rotaciones del rostro
  Future<List<List<double>>> generateAugmentedEmbeddings(img.Image image) async {
    final List<List<double>> embeddings = [];
    final List<int> angles = [-10, 0, 10]; // rotaciones en grados

    for (final angle in angles) {
      final rotated = img.copyRotate(image, angle: angle);
      final resized = img.copyResize(rotated, width: modelInputSize, height: modelInputSize);
      final Float32List input = imageToFloat32(resized);
      final List<List<double>> output = List.generate(1, (_) => List.filled(192, 0.0));
      _interpreter.run(input.reshape([1, modelInputSize, modelInputSize, 3]), output);
      embeddings.add(output[0]);
    }

    return embeddings;
  }

  /// Convierte imagen a Float32List normalizado para el modelo
  Float32List imageToFloat32(img.Image image) {
    final Float32List convertedBytes = Float32List(modelInputSize * modelInputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < modelInputSize; y++) {
      for (int x = 0; x < modelInputSize; x++) {
        final pixel = image.getPixel(x, y);

        convertedBytes[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        convertedBytes[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        convertedBytes[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }

    return convertedBytes;
  }

  /// Libera recursos del modelo
  void dispose() {
    _interpreter.close();
  }
}

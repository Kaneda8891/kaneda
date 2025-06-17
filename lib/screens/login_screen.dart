// screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import '../services/camera_service.dart';
import '../services/face_recognition_service.dart';
import '../services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cameraService = CameraService();
  final _faceService = FaceRecognitionService();
  final _storageService = StorageService();

  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _loginResult;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _cameraService.initializeCamera();
    await _faceService.loadModel();
    setState(() => _isInitialized = true);
  }

  Future<void> _authenticateUser() async {
    setState(() {
      _isProcessing = true;
      _loginResult = null;
    });

    final XFile? file = await _cameraService.takePicture();
    if (file == null) {
      setState(() => _isProcessing = false);
      return;
    }

    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      setState(() => _isProcessing = false);
      return;
    }

    final inputEmbedding = await _faceService.predict(image);
    final storedUsers = await _storageService.loadUserFaces();

    for (final user in storedUsers) {
      final distance = _compareEmbeddings(user.embedding, inputEmbedding);
      if (distance < 1.0) { // Puedes ajustar este umbral según pruebas
        setState(() {
          _loginResult = 'Bienvenido, ${user.name}!';
          _isProcessing = false;
        });
        return;
      }
    }

    setState(() {
      _loginResult = 'No se encontró coincidencia facial';
      _isProcessing = false;
    });
  }

  double _compareEmbeddings(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]) * (a[i] - b[i]);
    }
    return math.sqrt(sum);
  }

  @override
  void dispose() {
    _cameraService.disposeCamera();
    _faceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login facial')),
      body: Column(
        children: [
          if (_cameraService.cameraController.value.isInitialized)
            SizedBox(
              width: 300,
              height: 250,
              child: CameraPreview(_cameraService.cameraController),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isProcessing ? null : _authenticateUser,
            child: _isProcessing
                ? const CircularProgressIndicator()
                : const Text('Iniciar sesión con rostro'),
          ),
          const SizedBox(height: 20),
          if (_loginResult != null)
            Text(
              _loginResult!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

extension on double {
  double sqrt() => this >= 0 ? math.sqrt(this) : 0;
}

extension PowExtension on double {
    double pow(double exponent) => math.pow(this, exponent).toDouble();
} // Usa math en producción para mayor precisión

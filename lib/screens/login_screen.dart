// screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

import '../services/camera_service.dart';
import '../services/face_recognition_service.dart';
import '../services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final success = await _cameraService.initializeCamera();
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la cámara')),
        );
      }
      return;
    }

    await _faceService.loadModel();
    setState(() => _isInitialized = true);
  }

  Future<void> _authenticateUser() async {
    setState(() {
      _isProcessing = true;
      _loginResult = null;
    });

    // Tomar una foto con la cámara
    final XFile? file = await _cameraService.takePicture();
    if (file == null) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo tomar la foto.')),
        );
      }
      return;
    }

    // Convertir imagen a formato compatible para el modelo
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Imagen inválida.')));
      }
      return;
    }

    // Obtener el embedding de la imagen capturada
    final inputEmbedding = await _faceService.predict(image);

    // Cargar los usuarios registrados desde almacenamiento
    final storedUsers = await _storageService.loadUserFaces();

    // Comparar el embedding actual con los almacenados
    for (final user in storedUsers) {
      final distance = _compareEmbeddings(user.embedding, inputEmbedding);
      if (distance < 1.0) {
        // Puedes ajustar este umbral según pruebas
        setState(() {
          _loginResult = 'Bienvenido, ${user.name}!';
          _isProcessing = false;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('logueado', true);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/bienvenida');
        }
        return;
      }
    }

    // Si no se encontró coincidencia
    setState(() {
      _loginResult = 'No se encontró coincidencia facial';
      _isProcessing = false;
    });
  }

  // Cálculo de distancia euclidiana entre embeddings
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login facial')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_cameraService.cameraController.value.isInitialized)
              Center(
                // 🔹 Centro horizontal
                child: SizedBox(
                  width: 300,
                  height: 250,
                  child: CameraPreview(
                    _cameraService.cameraController,
                  ), // Vista previa cámara
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _authenticateUser,
              child: _isProcessing
                  ? const CircularProgressIndicator() // Indicador mientras procesa
                  : const Text('Iniciar sesión con rostro'),
            ),
            const SizedBox(height: 20),
            if (_loginResult != null)
              Text(
                _loginResult!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ), // Mensaje resultado
              ),
          ],
        ),
      ),
    );
  }
}

// Extensión para manejar raíz cuadrada
extension on double {
  double sqrt() => this >= 0 ? math.sqrt(this) : 0;
}

// Extensión para potencia
extension PowExtension on double {
  double pow(double exponent) => math.pow(this, exponent).toDouble();
} // Usa math en producción para mayor precisión

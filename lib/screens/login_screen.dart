import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import '../services/camera_service.dart';
import '../services/face_recognition_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cameraService = CameraService();
  final _faceService = FaceRecognitionService();

  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _loginResult;
  List<double>? _validEmbedding; // Embedding generado desde face.jpg

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Inicializa cámara y carga modelo + referencia
  Future<void> _initialize() async {
    final success = await _cameraService.initializeCamera();
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la cámara')),
        );
      }
      return;
    }

    await _faceService.loadModel(); // Carga el modelo .tflite
    await _loadReferenceEmbedding(); // Carga embedding desde face.jpg

    setState(() => _isInitialized = true);
  }

  /// Carga face.jpg desde assets y genera su embedding
  Future<void> _loadReferenceEmbedding() async {
    final byteData = await rootBundle.load('assets/tflite/face.jpg');
    final imageBytes = byteData.buffer.asUint8List();
    final image = img.decodeImage(imageBytes);
    if (image != null) {
      _validEmbedding = await _faceService.predict(
        image,
      ); // Aquí se genera el embedding de referencia
    }
  }

  /// AQUÍ HACE LA FUNCIÓN DE RECONOCIMIENTO FACIAL
  Future<void> _authenticateUser() async {
    if (_validEmbedding == null) return;

    setState(() {
      _isProcessing = true;
      _loginResult = null;
    });

    // Toma una foto desde la cámara frontal
    final XFile? file = await _cameraService.takePicture();
    if (file == null) {
      setState(() => _isProcessing = false);
      return;
    }

    // Convierte la imagen capturada en tipo img.Image
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      setState(() => _isProcessing = false);
      return;
    }

    // Genera el embedding del rostro capturado
    final inputEmbedding = await _faceService.predict(image);

    // Compara ambos embeddings (face.jpg vs rostro capturado)
    final distance = _compareEmbeddings(_validEmbedding!, inputEmbedding);
    print('Distancia: $distance'); // Para depuración

    // Si la distancia es suficientemente baja, hay coincidencia
    if (distance < 0.45) {
      // Coincidencia con el rostro autorizado
      setState(() {
        _loginResult = 'Acceso concedido';
        _isProcessing = false;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logueado', true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bienvenido. Rostro verificado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/bienvenida');
      }
    } else {
      // Rostro no coincide con face.jpg
      setState(() {
        _loginResult = 'Acceso denegado. Rostro no autorizado.';
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso denegado. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Calcula la distancia euclidiana entre dos embeddings
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
                child: SizedBox(
                  width: 320,
                  height: 480,
                  child: CameraPreview(_cameraService.cameraController),
                ),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

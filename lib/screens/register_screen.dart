// screens/register_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;
import '../services/camera_service.dart';
import '../services/face_recognition_service.dart';
import '../services/storage_service.dart';
import '../models/user_face_model.dart';

class RegisterScreen extends StatefulWidget {
  final String id;
  final String nombre;
  const RegisterScreen({super.key, required this.id, required this.nombre});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _cameraService = CameraService();
  final _faceService = FaceRecognitionService();
  final _storageService = StorageService();

  // Path to the neutral expression reference image included as an asset.
  final String _referenceImagePath = 'assets/tflite/face.jpg';

  // Distance threshold for validating that the expression is serious.
  final double _distanceThreshold = 1.0;

  // Embedding for the neutral expression reference image.
  List<double>? _referenceEmbedding;

  bool _isInitialized = false;
  bool _isProcessing = false;
  XFile? _capturedImage;

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
    final data = await rootBundle.load(_referenceImagePath);
    final bytes = data.buffer.asUint8List();
    final referenceImage = img.decodeImage(bytes);
    if (referenceImage != null) {
      _referenceEmbedding = await _faceService.predict(referenceImage);
    }
    setState(() => _isInitialized = true);
  }

  Future<void> _captureAndRegister() async {

    setState(() => _isProcessing = true);

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

    final embedding = await _faceService.predict(image);

    if (_referenceEmbedding != null) {
      final distance = UserFaceModel.euclideanDistance(
        embedding,
        _referenceEmbedding!,
      );
      if (distance > _distanceThreshold) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mantén una expresión seria y luminosa para registrar.'),
          ),
        );
        return;
      }
    }

    final user = UserFaceModel(
      name: widget.nombre.trim(),
      embedding: embedding,
      imagePath: file.path,
    );

    await _storageService.saveFaceImage(image, widget.id.trim());

    setState(() {
      _capturedImage = file;
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario registrado correctamente.')),
    );
    Navigator.pop(context, file.path);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Registro facial')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_cameraService.cameraController.value.isInitialized)
              SizedBox(
                width: 300,
                height: 250,
                child: CameraPreview(_cameraService.cameraController),
              ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _captureAndRegister,
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text('Registrar'),
            ),
            if (_capturedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Image.file(File(_capturedImage!.path), width: 150),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.disposeCamera();
    _faceService.dispose();
    super.dispose();
  }
}

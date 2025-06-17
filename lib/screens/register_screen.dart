// screens/register_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../services/camera_service.dart';
import '../services/face_recognition_service.dart';
import '../services/storage_service.dart';
import '../models/user_face_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _cameraService = CameraService();
  final _faceService = FaceRecognitionService();
  final _storageService = StorageService();

  bool _isInitialized = false;
  bool _isProcessing = false;
  XFile? _capturedImage;

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
    final user = UserFaceModel(
      name: _nameController.text.trim(),
      embedding: embedding,
    );

    await _storageService.saveUserFace(user);

    setState(() {
      _capturedImage = file;
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario registrado correctamente.')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      appBar: AppBar(title: const Text('Registrar rostro')),
      body: Column(
        children: [
          if (_cameraService.cameraController.value.isInitialized)
            AspectRatio(
              aspectRatio:
                  _cameraService.cameraController.value.aspectRatio,
              child: CameraPreview(_cameraService.cameraController),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del usuario',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isProcessing ? null : _captureAndRegister,
            child: _isProcessing
                ? const CircularProgressIndicator()
                : const Text('Capturar y registrar'),
          ),
          if (_capturedImage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Image.file(File(_capturedImage!.path), height: 160),
            ),
        ],
      ),
    );
  }
}

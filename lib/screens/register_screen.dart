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
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
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
    await _cameraService.initializeCamera();
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
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre.')),
      );
      return;
    }

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
      final distance =
          UserFaceModel.euclideanDistance(embedding, _referenceEmbedding!);
      if (distance > _distanceThreshold) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Mantén una expresión seria para registrarte.')));
        return;
      }
    }

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
}
///final
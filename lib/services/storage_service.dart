// services/storage_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_face_model.dart';

class StorageService {
  final String _key = 'user_faces';

  /// Guarda un nuevo usuario con su embedding facial
  Future<void> saveUserFace(UserFaceModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existing = prefs.getStringList(_key) ?? [];

    // Evitar duplicados (opcional): elimina si ya existe por nombre
    existing.removeWhere((jsonStr) {
      final existingUser = UserFaceModel.fromMap(jsonDecode(jsonStr));
      return existingUser.name == user.name;
    });

    existing.add(jsonEncode(user.toMap()));
    await prefs.setStringList(_key, existing);
  }

  Future<UserFaceModel?> getUserFace(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_key) ?? [];
    for (final jsonStr in stored) {
      final user = UserFaceModel.fromMap(jsonDecode(jsonStr));
      if (user.name == name) {
        return user;
      }
    }
    return null;
  }

  Future<void> removeUserFace(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_key) ?? [];
    stored.removeWhere((jsonStr) {
      final user = UserFaceModel.fromMap(jsonDecode(jsonStr));
      return user.name == name;
    });
    await prefs.setStringList(_key, stored);
  }

  /// Recupera todos los usuarios guardados
  Future<List<UserFaceModel>> loadUserFaces() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_key) ?? [];

    return stored
        .map((jsonStr) => UserFaceModel.fromMap(jsonDecode(jsonStr)))
        .toList();
  }

  /// Borra todos los usuarios registrados (útil para pruebas o reinicio)
  Future<void> clearAllFaces() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }


/// Guarda la imagen del rostro en la carpeta assets/tflite con el nombre
  /// igual al id del usuario en formato JPG.
  Future<void> saveFaceImage(img.Image faceImage, String id) async {
    final directory = Directory('assets/tflite');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    final path = p.join(directory.path, '$id.jpg');
    final jpgBytes = img.encodeJpg(faceImage);
    final file = File(path);
    await file.writeAsBytes(jpgBytes);
  }
}
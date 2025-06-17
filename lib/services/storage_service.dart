// services/storage_service.dart

import 'dart:convert';
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
}

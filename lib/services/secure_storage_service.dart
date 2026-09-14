import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._privateConstructor();

  static final SecureStorageService instance =
      SecureStorageService._privateConstructor();

  static const String _sessionTokenKey = 'session_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: false,
      migrateOnAlgorithmChange: true,
      migrateWithBackup: true,
    ),
  );

  Future<void> guardarTokenSesion(String token) async {
    try {
      await _storage.write(
        key: _sessionTokenKey,
        value: token,
      );

      debugPrint('PETCARE: TOKEN GUARDADO CORRECTAMENTE');
    } catch (e) {
      debugPrint('PETCARE: ERROR AL GUARDAR TOKEN: $e');
      rethrow;
    }
  }

  Future<String?> obtenerTokenSesion() async {
    try {
      final token = await _storage.read(
        key: _sessionTokenKey,
      );

      debugPrint(
        'PETCARE: TOKEN LEIDO: ${token != null && token.isNotEmpty}',
      );

      return token;
    } catch (e) {
      debugPrint('PETCARE: ERROR AL LEER TOKEN: $e');
      rethrow;
    }
  }

  Future<bool> existeSesion() async {
    try {
      final token = await obtenerTokenSesion();

      final existe = token != null && token.isNotEmpty;

      debugPrint('PETCARE: EXISTE SESION: $existe');

      return existe;
    } catch (e) {
      debugPrint('PETCARE: ERROR COMPROBANDO SESION: $e');
      rethrow;
    }
  }

  Future<void> eliminarSesion() async {
    try {
      await _storage.delete(
        key: _sessionTokenKey,
      );

      debugPrint('PETCARE: SESION ELIMINADA');
    } catch (e) {
      debugPrint('PETCARE: ERROR AL ELIMINAR SESION: $e');
      rethrow;
    }
  }
}
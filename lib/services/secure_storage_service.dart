import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._privateConstructor();

  static final SecureStorageService instance =
      SecureStorageService._privateConstructor();

  // =========================================================
  // CLAVES DE ALMACENAMIENTO
  // =========================================================

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // =========================================================
  // ALMACENAMIENTO SEGURO
  // =========================================================

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: false,
      migrateOnAlgorithmChange: true,
      migrateWithBackup: true,
    ),
  );

  // =========================================================
  // GUARDAR ACCESS TOKEN
  // =========================================================

  Future<void> guardarAccessToken(
    String token,
  ) async {
    try {
      await _storage.write(
        key: _accessTokenKey,
        value: token,
      );

      debugPrint(
        'PETCARE: ACCESS TOKEN GUARDADO CORRECTAMENTE',
      );
    } catch (e) {
      debugPrint(
        'PETCARE: ERROR AL GUARDAR ACCESS TOKEN: $e',
      );
      rethrow;
    }
  }

  // =========================================================
  // OBTENER ACCESS TOKEN
  // =========================================================

  Future<String?> obtenerAccessToken() async {
    try {
      final token = await _storage.read(
        key: _accessTokenKey,
      );

      debugPrint(
        'PETCARE: ACCESS TOKEN LEIDO: '
        '${token != null && token.isNotEmpty}',
      );

      return token;
    } catch (e) {
      debugPrint(
        'PETCARE: ERROR AL LEER ACCESS TOKEN: $e',
      );
      rethrow;
    }
  }

  // =========================================================
  // GUARDAR REFRESH TOKEN
  // =========================================================

  Future<void> guardarRefreshToken(
    String token,
  ) async {
    try {
      await _storage.write(
        key: _refreshTokenKey,
        value: token,
      );

      debugPrint(
        'PETCARE: REFRESH TOKEN GUARDADO CORRECTAMENTE',
      );
    } catch (e) {
      debugPrint(
        'PETCARE: ERROR AL GUARDAR REFRESH TOKEN: $e',
      );
      rethrow;
    }
  }

  // =========================================================
  // OBTENER REFRESH TOKEN
  // =========================================================

  Future<String?> obtenerRefreshToken() async {
    try {
      final token = await _storage.read(
        key: _refreshTokenKey,
      );

      debugPrint(
        'PETCARE: REFRESH TOKEN LEIDO: '
        '${token != null && token.isNotEmpty}',
      );

      return token;
    } catch (e) {
      debugPrint(
        'PETCARE: ERROR AL LEER REFRESH TOKEN: $e',
      );
      rethrow;
    }
  }

  // =========================================================
  // GUARDAR TOKENS DE SESION
  // =========================================================

  Future<void> guardarTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(
        key: _accessTokenKey,
        value: accessToken,
      );

      await _storage.write(
        key: _refreshTokenKey,
        value: refreshToken,
      );

      debugPrint(
        'PETCARE: TOKENS DE SESION GUARDADOS CORRECTAMENTE',
      );
    } catch (e) {
      debugPrint(
        'PETCARE: ERROR AL GUARDAR TOKENS: $e',
      );
      rethrow;
    }
  }

  // =========================================================
  // COMPROBAR SI EXISTE SESION
  // =========================================================

  Future<bool> existeSesion() async {
    try {
      final accessToken = await obtenerAccessToken();
      final refreshToken = await obtenerRefreshToken();

      final existe =
          accessToken != null &&
          accessToken.isNotEmpty &&
          refreshToken != null &&
          refreshToken.isNotEmpty;

      debugPrint(
        'PETCARE: EXISTE SESION: $existe',
      );

      return existe;
    } catch (e) {
      debugPrint(
        'PETCARE: ERROR COMPROBANDO SESION: $e',
      );
      rethrow;
    }
  }

  // =========================================================
  // ELIMINAR SESION COMPLETA
  // =========================================================

  Future<void> eliminarSesion() async {
    try {
      await _storage.delete(
        key: _accessTokenKey,
      );

      await _storage.delete(
        key: _refreshTokenKey,
      );

      debugPrint(
        'PETCARE: ACCESS Y REFRESH TOKENS ELIMINADOS',
      );
    } catch (e) {
      debugPrint(
        'PETCARE: ERROR AL ELIMINAR SESION: $e',
      );
      rethrow;
    }
  }
}
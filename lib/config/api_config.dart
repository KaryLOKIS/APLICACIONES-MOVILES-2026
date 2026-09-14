class ApiConfig {
  ApiConfig._();

  // =========================================================
  // CONFIGURACION DEL BACKEND
  // =========================================================

  // Android Emulator:
  // 10.0.2.2 representa la computadora donde se ejecuta
  // nuestro servidor local.
  static const String baseUrl =
      'http://10.0.2.2:3000';

  // =========================================================
  // TIMEOUTS
  // =========================================================

  static const Duration connectTimeout =
      Duration(seconds: 10);

  static const Duration receiveTimeout =
      Duration(seconds: 15);

  static const Duration sendTimeout =
      Duration(seconds: 15);

  // =========================================================
  // ENDPOINTS DE AUTENTICACION
  // =========================================================

  static const String loginEndpoint =
      '/api/auth/login';

  static const String registerEndpoint =
      '/api/auth/register';

  static const String refreshEndpoint =
      '/api/auth/refresh';

  static const String meEndpoint =
      '/api/auth/me';

  // =========================================================
  // ENDPOINTS DE MASCOTAS
  // =========================================================

  static const String petsEndpoint =
      '/api/pets';
}
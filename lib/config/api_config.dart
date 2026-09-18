class ApiConfig {
  ApiConfig._();

  // ==========================================
  // DIRECCIÓN DEL BACKEND
  // ==========================================
  //
  // En desarrollo se utiliza el backend local.
  // Para producción se puede indicar otra URL
  // mediante --dart-define=API_BASE_URL=...
  //

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  // ==========================================
  // TIEMPOS DE ESPERA
  // ==========================================

  static const Duration connectTimeout =
      Duration(seconds: 10);

  static const Duration receiveTimeout =
      Duration(seconds: 15);

  static const Duration sendTimeout =
      Duration(seconds: 15);

  // ==========================================
  // ENDPOINTS DE AUTENTICACIÓN
  // ==========================================

  static const String loginEndpoint =
      '/api/auth/login';

  static const String registerEndpoint =
      '/api/auth/register';

  static const String refreshEndpoint =
      '/api/auth/refresh';

  static const String meEndpoint =
      '/api/auth/me';

  // ==========================================
  // ENDPOINTS DE MASCOTAS
  // ==========================================

  static const String petsEndpoint =
      '/api/pets';
}
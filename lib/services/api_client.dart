import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'secure_storage_service.dart';

class ApiClient {
  ApiClient._privateConstructor();

  static final ApiClient instance =
      ApiClient._privateConstructor();

  final SecureStorageService _secureStorage =
      SecureStorageService.instance;

  late final Dio dio = _crearDio();

  // =========================================================
  // CREAR CLIENTE HTTP
  // =========================================================

  Dio _crearDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // -------------------------------------------------------
    // INTERCEPTOR DE AUTENTICACION
    // -------------------------------------------------------

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken =
              await _secureStorage.obtenerAccessToken();

          if (accessToken != null &&
              accessToken.isNotEmpty) {
            options.headers['Authorization'] =
                'Bearer $accessToken';
          }

          handler.next(options);
        },

        onError: (error, handler) async {
          // -------------------------------------------------
          // SI NO ES 401, CONTINUAR NORMALMENTE
          // -------------------------------------------------

          if (error.response?.statusCode != 401) {
            handler.next(error);
            return;
          }

          // -------------------------------------------------
          // EVITAR BUCLE INFINITO
          // -------------------------------------------------

          final requestOptions = error.requestOptions;

          final yaReintentado =
              requestOptions.extra['retry'] == true;

          if (yaReintentado) {
            handler.next(error);
            return;
          }

          // -------------------------------------------------
          // NO INTENTAR RENOVAR EL TOKEN EN EL ENDPOINT
          // DE REFRESH
          // -------------------------------------------------

          if (requestOptions.path ==
              ApiConfig.refreshEndpoint) {
            handler.next(error);
            return;
          }

          try {
            requestOptions.extra['retry'] = true;

            final nuevoAccessToken =
                await _renovarAccessToken();

            if (nuevoAccessToken == null ||
                nuevoAccessToken.isEmpty) {
              handler.next(error);
              return;
            }

            // -----------------------------------------------
            // ACTUALIZAR TOKEN DE LA SOLICITUD ORIGINAL
            // -----------------------------------------------

            requestOptions.headers['Authorization'] =
                'Bearer $nuevoAccessToken';

            // -----------------------------------------------
            // REPETIR SOLICITUD ORIGINAL
            // -----------------------------------------------

            final response = await dio.fetch(
              requestOptions,
            );

            handler.resolve(response);
          } catch (_) {
            await _secureStorage.eliminarSesion();

            handler.next(error);
          }
        },
      ),
    );

    return dio;
  }

  // =========================================================
  // RENOVAR ACCESS TOKEN
  // =========================================================

  Future<String?> _renovarAccessToken() async {
    final refreshToken =
        await _secureStorage.obtenerRefreshToken();

    if (refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final response = await refreshDio.post(
      ApiConfig.refreshEndpoint,
      data: {
        'refresh_token': refreshToken,
      },
    );

    final data = response.data;

    if (data is! Map) {
      return null;
    }

    final accessToken =
        data['access_token'] as String?;

    final nuevoRefreshToken =
        data['refresh_token'] as String?;

    if (accessToken == null ||
        accessToken.isEmpty) {
      return null;
    }

    if (nuevoRefreshToken == null ||
        nuevoRefreshToken.isEmpty) {
      return null;
    }

    await _secureStorage.guardarTokens(
      accessToken: accessToken,
      refreshToken: nuevoRefreshToken,
    );

    return accessToken;
  }
}
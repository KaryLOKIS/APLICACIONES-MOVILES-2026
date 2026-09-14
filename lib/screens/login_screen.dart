import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/secure_storage_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController correoController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final SecureStorageService _secureStorage =
      SecureStorageService.instance;

  final Dio _dio = ApiClient.instance.dio;

  bool ocultarPassword = true;
  bool iniciandoSesion = false;

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    final correo = correoController.text.trim();

    // No hacemos trim de la contraseña porque los espacios
    // podrían formar parte de la contraseña real.
    final password = passwordController.text;

    if (correo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, completa el correo y la contraseña.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      iniciandoSesion = true;
    });

    try {
      final response = await _dio.post(
        ApiConfig.loginEndpoint,
        data: {
          'email': correo,
          'password': password,
        },
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception(
          'El servidor devolvió una respuesta inválida.',
        );
      }

      final accessToken =
          data['access_token'] as String?;

      final refreshToken =
          data['refresh_token'] as String?;

      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        throw Exception(
          'El servidor no devolvió los tokens de sesión.',
        );
      }

      // Guardamos ambos tokens en almacenamiento seguro.
      await _secureStorage.guardarTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inicio de sesión correcto. 🐾',
          ),
          backgroundColor: Colors.teal,
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }

      String mensaje =
          'No se pudo conectar con el servidor.';

      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      if (statusCode == 401) {
        mensaje =
            'Correo o contraseña incorrectos.';
      } else if (statusCode == 422) {
        mensaje =
            _obtenerMensajeValidacion(responseData);
      } else if (e.type ==
          DioExceptionType.connectionTimeout) {
        mensaje =
            'Tiempo de conexión agotado. Verifica el servidor.';
      } else if (e.type ==
          DioExceptionType.receiveTimeout) {
        mensaje =
            'El servidor tardó demasiado en responder.';
      } else if (e.type ==
          DioExceptionType.connectionError) {
        mensaje =
            'No hay conexión con el servidor. '
            'Verifica que el backend esté ejecutándose.';
      } else if (statusCode != null &&
          statusCode >= 500) {
        mensaje =
            'El servidor presentó un error. '
            'Intenta nuevamente.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo iniciar la sesión: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          iniciandoSesion = false;
        });
      }
    }
  }

  String _obtenerMensajeValidacion(dynamic data) {
    if (data is Map) {
      final errores = data['errores'];

      if (errores is List && errores.isNotEmpty) {
        final primerError = errores.first;

        if (primerError is Map) {
          final mensaje =
              primerError['msg'] ??
              primerError['message'] ??
              primerError['mensaje'];

          if (mensaje is String &&
              mensaje.isNotEmpty) {
            return mensaje;
          }
        }

        if (primerError is String &&
            primerError.isNotEmpty) {
          return primerError;
        }
      }

      final mensaje =
          data['mensaje'] ??
          data['message'] ??
          data['error'];

      if (mensaje is String && mensaje.isNotEmpty) {
        return mensaje;
      }
    }

    return 'Revisa los datos ingresados.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text(
          'Iniciar sesión',
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 35),

            const Icon(
              Icons.pets,
              size: 90,
              color: Colors.teal,
            ),

            const SizedBox(height: 20),

            const Text(
              'Bienvenido a PetCare',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Ingresa a tu cuenta',
              style: TextStyle(
                fontSize: 17,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 35),

            TextField(
              controller: correoController,
              keyboardType:
                  TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'ejemplo@correo.com',
                prefixIcon: const Icon(
                  Icons.email,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: ocultarPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(
                  Icons.lock,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    ocultarPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      ocultarPassword =
                          !ocultarPassword;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'La recuperación de contraseña estará disponible próximamente.',
                      ),
                    ),
                  );
                },
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: iniciandoSesion
                    ? null
                    : iniciarSesion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.teal.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: iniciandoSesion
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<
                                  Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Text(
                  '¿No tienes una cuenta?',
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Registrarse',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
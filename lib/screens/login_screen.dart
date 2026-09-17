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
    final email = correoController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
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
      debugPrint('PETCARE LOGIN: enviando solicitud al backend...');
      debugPrint('PETCARE LOGIN: correo = $email');

      final response = await _dio.post(
        ApiConfig.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      debugPrint(
        'PETCARE LOGIN: respuesta HTTP = ${response.statusCode}',
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception(
          'El servidor devolvió una respuesta inválida.',
        );
      }

      final accessToken = data['access_token']?.toString();
      final refreshToken = data['refresh_token']?.toString();

      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        throw Exception(
          'El servidor no devolvió los tokens de sesión.',
        );
      }

      await _secureStorage.guardarTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      debugPrint(
        'PETCARE LOGIN: tokens guardados correctamente.',
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

      debugPrint(
        'PETCARE LOGIN: ERROR DIO = ${e.message}',
      );

      debugPrint(
        'PETCARE LOGIN: STATUS = ${e.response?.statusCode}',
      );

      debugPrint(
        'PETCARE LOGIN: RESPUESTA = ${e.response?.data}',
      );

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
          DioExceptionType.sendTimeout) {
        mensaje =
            'Tiempo de envío agotado. Verifica la conexión.';
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
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint(
        'PETCARE LOGIN: ERROR GENERAL = $e',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo iniciar la sesión: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
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
        final mensajes = <String>[];

        for (final error in errores) {
          if (error is Map) {
            final mensaje =
                error['msg'] ??
                error['message'] ??
                error['mensaje'];

            if (mensaje is String &&
                mensaje.trim().isNotEmpty) {
              mensajes.add(mensaje.trim());
            }
          } else if (error is String &&
              error.trim().isNotEmpty) {
            mensajes.add(error.trim());
          }
        }

        if (mensajes.isNotEmpty) {
          return mensajes.join('\n');
        }
      }

      final mensaje =
          data['mensaje'] ??
          data['message'] ??
          data['error'];

      if (mensaje is String &&
          mensaje.trim().isNotEmpty) {
        return mensaje.trim();
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
              textInputAction:
                  TextInputAction.next,
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
              textInputAction:
                  TextInputAction.done,
              onSubmitted: (_) {
                if (!iniciandoSesion) {
                  iniciarSesion();
                }
              },
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
              alignment:
                  Alignment.centerRight,
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
                  shape:
                      RoundedRectangleBorder(
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
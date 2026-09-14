import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/database_service.dart';
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

  final DatabaseService _databaseService =
      DatabaseService.instance;

  final SecureStorageService _secureStorage =
      SecureStorageService.instance;

  final Uuid _uuid = const Uuid();

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
      final usuario = await _databaseService.validarCredenciales(
        correo: correo,
        password: password,
      );

      if (!mounted) {
        return;
      }

      if (usuario == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Correo o contraseña incorrectos.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      /*
       * La autenticación local fue correcta.
       *
       * Como todavía no tenemos un backend,
       * generamos un identificador único de sesión
       * y lo almacenamos mediante flutter_secure_storage.
       *
       * En una versión conectada a una API,
       * aquí se almacenaría el token entregado por el servidor.
       */
      final tokenSesion = _uuid.v4();

      await _secureStorage.guardarTokenSesion(
        tokenSesion,
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
              keyboardType: TextInputType.emailAddress,

              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'ejemplo@correo.com',
                prefixIcon: const Icon(
                  Icons.email,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,

              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
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
                onPressed:
                    iniciandoSesion
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
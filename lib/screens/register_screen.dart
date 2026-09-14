import 'package:flutter/material.dart';

import '../services/database_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController =
      TextEditingController();

  final TextEditingController _correoController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final DatabaseService _databaseService =
      DatabaseService.instance;

  bool _mostrarPassword = false;
  bool _mostrarConfirmPassword = false;
  bool _creandoCuenta = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // =========================================================
  // CREAR CUENTA
  // =========================================================

  Future<void> _crearCuenta() async {
    // ---------------------------------------------------------
    // VALIDAR FORMULARIO
    // ---------------------------------------------------------

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _creandoCuenta = true;
    });

    try {
      final nombre = _nombreController.text.trim();
      final correo = _correoController.text.trim().toLowerCase();
      final password = _passwordController.text;

      // -------------------------------------------------------
      // REGISTRAR USUARIO EN SQLITE
      // -------------------------------------------------------

      final registrado =
          await _databaseService.registrarUsuario(
        nombre: nombre,
        correo: correo,
        password: password,
      );

      if (!mounted) {
        return;
      }

      // -------------------------------------------------------
      // CORREO YA REGISTRADO
      // -------------------------------------------------------

      if (!registrado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este correo ya está registrado. '
              'Utiliza otro correo.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }

      // -------------------------------------------------------
      // REGISTRO CORRECTO
      // -------------------------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Cuenta creada correctamente! 🐾',
          ),
          backgroundColor: Colors.teal,
        ),
      );

      // -------------------------------------------------------
      // REGRESAR AL LOGIN
      // -------------------------------------------------------

      await Future.delayed(
        const Duration(milliseconds: 1200),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo crear la cuenta: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creandoCuenta = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,

      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text(
          'Crear cuenta',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Form(
            key: _formKey,

            child: Column(
              children: [
                const SizedBox(height: 20),

                // =================================================
                // ICONO
                // =================================================

                const Icon(
                  Icons.pets,
                  size: 100,
                  color: Colors.teal,
                ),

                const SizedBox(height: 20),

                // =================================================
                // TÍTULO
                // =================================================

                const Text(
                  'Crear una cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),

                const SizedBox(height: 12),

                // =================================================
                // DESCRIPCIÓN
                // =================================================

                const Text(
                  'Regístrate para comenzar a cuidar la salud de tu mascota',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 35),

                // =================================================
                // NOMBRE
                // =================================================

                TextFormField(
                  controller: _nombreController,
                  keyboardType: TextInputType.name,

                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Ingresa tu nombre completo';
                    }

                    if (value.trim().length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // =================================================
                // CORREO
                // =================================================

                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,

                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email),
                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Ingresa tu correo electrónico';
                    }

                    final emailRegex = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

                    if (!emailRegex.hasMatch(
                      value.trim(),
                    )) {
                      return 'Ingresa un correo electrónico válido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // =================================================
                // CONTRASEÑA
                // =================================================

                TextFormField(
                  controller: _passwordController,
                  obscureText: !_mostrarPassword,

                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),

                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),

                      onPressed: () {
                        setState(() {
                          _mostrarPassword =
                              !_mostrarPassword;
                        });
                      },
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa una contraseña';
                    }

                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // =================================================
                // CONFIRMAR CONTRASEÑA
                // =================================================

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_mostrarConfirmPassword,

                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),

                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),

                      onPressed: () {
                        setState(() {
                          _mostrarConfirmPassword =
                              !_mostrarConfirmPassword;
                        });
                      },
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }

                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // =================================================
                // BOTÓN CREAR CUENTA
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed:
                        _creandoCuenta ? null : _crearCuenta,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,

                      disabledBackgroundColor:
                          Colors.teal.shade200,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    child: _creandoCuenta
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Crear cuenta',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                // =================================================
                // VOLVER A INICIAR SESIÓN
                // =================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    const Text(
                      '¿Ya tienes una cuenta?',
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),

                    TextButton(
                      onPressed: _creandoCuenta
                          ? null
                          : () {
                              Navigator.pop(context);
                            },

                      child: const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
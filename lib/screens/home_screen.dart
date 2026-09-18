import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import 'login_screen.dart';
import 'pets_screen.dart';
import 'reminders_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Cerrar sesión',
          ),
          content: const Text(
            'Al cerrar sesión se eliminarán los datos almacenados '
            'localmente en este dispositivo. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Cerrar sesión',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await SecureStorageService.instance.eliminarSesion();

      await DatabaseService.instance.eliminarBaseDatos();

      if (!context.mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo cerrar la sesión: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _abrirMascotas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PetsScreen(),
      ),
    );
  }

  void _abrirRecordatorios(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RemindersScreen(),
      ),
    );
  }

  void _mostrarProximamente(
    BuildContext context,
    String seccion,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'La sección "$seccion" será implementada en el siguiente paso.',
        ),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,

      // =====================================================
      // BARRA SUPERIOR
      // =====================================================
      appBar: AppBar(
        title: const Text(
          'PetCare',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(
              Icons.logout,
            ),
            onPressed: () {
              _cerrarSesion(context);
            },
          ),
        ],
      ),

      // =====================================================
      // CONTENIDO
      // =====================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // =================================================
            // MENSAJE DE BIENVENIDA
            // =================================================
            const Text(
              '¡Bienvenido a PetCare! 🐾',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Cuida la salud y el bienestar de tus mascotas.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 25),

            // =================================================
            // MIS MASCOTAS
            // =================================================
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  _abrirMascotas(context);
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 40,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 18),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mis mascotas',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Registra y administra la información '
                              'de tus mascotas.',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // =================================================
            // RECORDATORIOS
            // =================================================
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  _abrirRecordatorios(context);
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications,
                      color: Colors.orange,
                    ),
                  ),
                  title: const Text(
                    'Recordatorios',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: const Text(
                    'Vacunas, desparasitación y citas veterinarias.',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // =================================================
            // CITAS VETERINARIAS
            // =================================================
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  _mostrarProximamente(
                    context,
                    'Citas veterinarias',
                  );
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Colors.blue,
                    ),
                  ),
                  title: const Text(
                    'Citas veterinarias',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: const Text(
                    'Consulta y organiza las próximas citas.',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // =================================================
            // SALUD DE LA MASCOTA
            // =================================================
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  _mostrarProximamente(
                    context,
                    'Salud de mi mascota',
                  );
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                  ),
                  title: const Text(
                    'Salud de mi mascota',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: const Text(
                    'Consulta el historial y datos importantes.',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =================================================
            // BOTÓN AGREGAR MASCOTA
            // =================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  _abrirMascotas(context);
                },
                icon: const Icon(
                  Icons.add,
                ),
                label: const Text(
                  'Agregar mascota',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      // =====================================================
      // MENÚ INFERIOR
      // =====================================================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,

        onTap: (index) {
          if (index == 0) {
            return;
          }

          if (index == 1) {
            _abrirMascotas(context);
            return;
          }

          if (index == 2) {
            _abrirRecordatorios(context);
            return;
          }

          if (index == 3) {
            _mostrarProximamente(
              context,
              'Perfil',
            );
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Mascotas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Recordatorios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
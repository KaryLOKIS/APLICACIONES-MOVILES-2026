import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import 'appointments_screen.dart';
import 'login_screen.dart';
import 'pets_screen.dart';
import 'reminders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SecureStorageService _secureStorage =
      SecureStorageService.instance;

  final DatabaseService _databaseService =
      DatabaseService.instance;

  int _indiceSeleccionado = 0;

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '¿Deseas cerrar sesión?\n\n'
            'Se eliminarán los datos locales almacenados '
            'en este dispositivo.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.teal.shade700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await _secureStorage.eliminarSesion();
      await _databaseService.eliminarBaseDatos();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo cerrar la sesión: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // NAVEGACIÓN
  // ============================================================

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

  void _abrirCitasVeterinarias(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppointmentsScreen(),
      ),
    );
  }

  void _abrirSalud(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.teal.shade700,
        content: const Text(
          'La sección de salud estará disponible '
          'desde el perfil de cada mascota.',
        ),
      ),
    );
  }

  void _seleccionarMenu(int indice) {
    setState(() {
      _indiceSeleccionado = indice;
    });

    switch (indice) {
      case 0:
        break;

      case 1:
        _abrirMascotas(context);
        break;

      case 2:
        _abrirRecordatorios(context);
        break;

      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal.shade700,
            content: const Text(
              'La sección de perfil estará disponible '
              'próximamente.',
            ),
          ),
        );
        break;
    }
  }

  // ============================================================
  // TARJETA PRINCIPAL
  // ============================================================

  Widget _crearTarjetaMenu({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              // ICONO
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icono,
                  color: Colors.teal.shade700,
                  size: 29,
                ),
              ),

              const SizedBox(width: 16),

              // TEXTO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // FLECHA
              Icon(
                Icons.arrow_forward_ios,
                size: 17,
                color: Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'PetCare',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      // ========================================================
      // CONTENIDO
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            14,
            20,
            14,
            25,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // BIENVENIDA
              // --------------------------------------------------

              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Text(
                  '¡Bienvenido a PetCare! 🐾',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Text(
                  'Cuida la salud y el bienestar de tus mascotas '
                  'desde un solo lugar.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // MIS MASCOTAS
              // --------------------------------------------------

              _crearTarjetaMenu(
                icono: Icons.pets,
                titulo: 'Mis mascotas',
                descripcion:
                    'Consulta y administra la información '
                    'de tus mascotas.',
                onTap: () {
                  _abrirMascotas(context);
                },
              ),

              const SizedBox(height: 14),

              // --------------------------------------------------
              // RECORDATORIOS
              // --------------------------------------------------

              _crearTarjetaMenu(
                icono: Icons.notifications_active,
                titulo: 'Recordatorios',
                descripcion:
                    'Consulta y administra los recordatorios '
                    'de cuidado.',
                onTap: () {
                  _abrirRecordatorios(context);
                },
              ),

              const SizedBox(height: 14),

              // --------------------------------------------------
              // CITAS VETERINARIAS
              // --------------------------------------------------

              _crearTarjetaMenu(
                icono: Icons.calendar_month,
                titulo: 'Citas veterinarias',
                descripcion:
                    'Registra y consulta las citas '
                    'veterinarias de tus mascotas.',
                onTap: () {
                  _abrirCitasVeterinarias(context);
                },
              ),

              const SizedBox(height: 14),

              // --------------------------------------------------
              // SALUD
              // --------------------------------------------------

              _crearTarjetaMenu(
                icono: Icons.health_and_safety,
                titulo: 'Salud de mi mascota',
                descripcion:
                    'Consulta información relacionada '
                    'con la salud de tus mascotas.',
                onTap: () {
                  _abrirSalud(context);
                },
              ),

              const SizedBox(height: 22),

              // --------------------------------------------------
              // BOTÓN AGREGAR MASCOTA
              // --------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _abrirMascotas(context);
                  },
                  icon: Icon(
                    Icons.add,
                    color: Colors.teal.shade700,
                  ),
                  label: Text(
                    'Agregar mascota',
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.teal.shade100,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ========================================================
      // BARRA DE NAVEGACIÓN
      // ========================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal.shade700,
        unselectedItemColor: Colors.grey.shade500,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        onTap: _seleccionarMenu,
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
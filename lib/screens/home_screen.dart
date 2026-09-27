import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';

import 'appointments_screen.dart';
import 'login_screen.dart';
import 'pets_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final SecureStorageService _secureStorageService =
      SecureStorageService.instance;

  List<Pet> _mascotas = [];
  List<Map<String, dynamic>> _citas = [];
  List<Map<String, dynamic>> _recordatorios = [];
  List<Map<String, dynamic>> _vacunas = [];
  List<Map<String, dynamic>> _desparasitaciones = [];

  String? _mascotaActivaId;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ============================================================
  // CARGAR DATOS
  // ============================================================

  Future<void> _cargarDatos() async {
    try {
      final resultados = await Future.wait([
        _databaseService.obtenerMascotas(),
        _databaseService.obtenerCitasVeterinarias(),
        _databaseService.obtenerRecordatorios(),
        _databaseService.obtenerTodasLasVacunas(),
        _databaseService.obtenerTodasLasDesparasitaciones(),
      ]);

      if (!mounted) return;

      final mascotas = (resultados[0] as List<Pet>)
          .where((mascota) => !mascota.deleted)
          .toList();

      final citas =
          resultados[1] as List<Map<String, dynamic>>;

      final recordatorios =
          resultados[2] as List<Map<String, dynamic>>;

      final vacunas =
          resultados[3] as List<Map<String, dynamic>>;

      final desparasitaciones =
          resultados[4] as List<Map<String, dynamic>>;

      mascotas.sort(
        (a, b) => a.nombre.compareTo(b.nombre),
      );

      setState(() {
        _mascotas = mascotas;
        _citas = citas;
        _recordatorios = recordatorios;
        _vacunas = vacunas;
        _desparasitaciones = desparasitaciones;

        if (_mascotas.isEmpty) {
          _mascotaActivaId = null;
        } else {
          final existeMascotaActiva = _mascotas.any(
            (mascota) => mascota.id == _mascotaActivaId,
          );

          if (!existeMascotaActiva) {
            _mascotaActivaId = _mascotas.first.id;
          }
        }

        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'No se pudo cargar el inicio: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // MASCOTA ACTIVA
  // ============================================================

  Pet? get _mascotaActiva {
    if (_mascotas.isEmpty || _mascotaActivaId == null) {
      return null;
    }

    try {
      return _mascotas.firstWhere(
        (mascota) => mascota.id == _mascotaActivaId,
      );
    } catch (_) {
      return _mascotas.first;
    }
  }

  Pet? _buscarMascotaPorId(String petId) {
    if (petId.trim().isEmpty) {
      return null;
    }

    try {
      return _mascotas.firstWhere(
        (mascota) => mascota.id == petId,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // NAVEGACIÓN
  // ============================================================

  Future<void> _abrirMascotas() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PetsScreen(),
      ),
    );

    await _cargarDatos();
  }

  Future<void> _abrirAgenda() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RemindersScreen(),
      ),
    );

    await _cargarDatos();
  }

  Future<void> _abrirCitas() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AppointmentsScreen(),
      ),
    );

    await _cargarDatos();
  }

  Future<void> _abrirPerfil() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );

    if (!mounted) return;

    await _cargarDatos();
  }

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
            '¿Salir de PetCare?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Tendrás que iniciar sesión nuevamente para acceder a tu cuenta.',
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
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _secureStorageService.eliminarSesion();
      await _databaseService.eliminarBaseDatos();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'No se pudo cerrar la sesión: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CONVERTIR FECHAS
  //
  // Soporta:
  // 27/10/2026
  // 2026-10-27
  // 2026-10-27T00:00:00.000
  // ============================================================

  DateTime? _convertirFecha(String fecha) {
    try {
      final texto = fecha.trim();

      if (texto.isEmpty) {
        return null;
      }

      // DD/MM/YYYY
      if (texto.contains('/')) {
        final partes = texto.split('/');

        if (partes.length != 3) {
          return null;
        }

        return DateTime(
          int.parse(partes[2]),
          int.parse(partes[1]),
          int.parse(partes[0]),
        );
      }

      // ISO
      final fechaIso = DateTime.tryParse(texto);

      if (fechaIso != null) {
        return DateTime(
          fechaIso.year,
          fechaIso.month,
          fechaIso.day,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  DateTime _fechaSinHora(DateTime fecha) {
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    );
  }

  // ============================================================
  // PRÓXIMOS EVENTOS
  //
  // IMPORTANTE:
  // - Citas: fecha
  // - Vacunas: fecha_aplicacion
  // - Desparasitación: fecha_aplicacion
  //
  // Ya NO usamos proxima_dosis.
  // ============================================================

  List<Map<String, dynamic>> _obtenerProximosEventos() {
    final eventos = <Map<String, dynamic>>[];

    final hoy = _fechaSinHora(DateTime.now());

    // ----------------------------------------------------------
    // CITAS VETERINARIAS
    // ----------------------------------------------------------

    for (final cita in _citas) {
      final fechaTexto =
          cita['fecha']?.toString().trim() ?? '';

      final fecha = _convertirFecha(fechaTexto);

      if (fecha == null) continue;

      if (_fechaSinHora(fecha).isBefore(hoy)) {
        continue;
      }

      final motivo =
          cita['motivo']?.toString().trim() ?? '';

      eventos.add({
        'origen': 'cita',
        'tipo': 'Cita veterinaria',
        'titulo':
            motivo.isNotEmpty ? motivo : 'Cita veterinaria',
        'mascota':
            cita['mascota']?.toString().trim() ?? '',
        'veterinario':
            cita['veterinario']?.toString().trim() ?? '',
        'fecha': fecha,
        'hora': cita['hora']?.toString().trim() ?? '',
      });
    }

    // ----------------------------------------------------------
    // RECORDATORIOS ANTIGUOS
    //
    // Se mantienen por compatibilidad con los registros que
    // ya existan en la base de datos.
    // ----------------------------------------------------------

    for (final recordatorio in _recordatorios) {
      final fechaTexto =
          recordatorio['fecha']?.toString().trim() ?? '';

      final fecha = _convertirFecha(fechaTexto);

      if (fecha == null) continue;

      if (_fechaSinHora(fecha).isBefore(hoy)) {
        continue;
      }

      eventos.add({
        'origen': 'recordatorio',
        'tipo':
            recordatorio['tipo']?.toString().trim() ?? 'Otro',
        'titulo':
            recordatorio['titulo']?.toString().trim() ??
                'Recordatorio',
        'mascota':
            recordatorio['mascota']?.toString().trim() ?? '',
        'veterinario': '',
        'fecha': fecha,
        'hora': '',
      });
    }

    // ----------------------------------------------------------
    // VACUNAS
    //
    // AHORA USAMOS fecha_aplicacion
    // ----------------------------------------------------------

    for (final vacuna in _vacunas) {
      final fechaTexto =
          vacuna['fecha_aplicacion']?.toString().trim() ?? '';

      if (fechaTexto.isEmpty) {
        continue;
      }

      final fecha = _convertirFecha(fechaTexto);

      if (fecha == null) {
        continue;
      }

      // Solo hoy o fechas futuras.
      if (_fechaSinHora(fecha).isBefore(hoy)) {
        continue;
      }

      final petId =
          vacuna['pet_id']?.toString().trim() ?? '';

      final mascota = _buscarMascotaPorId(petId);

      if (mascota == null) {
        continue;
      }

      final nombreVacuna =
          vacuna['vacuna']?.toString().trim() ?? '';

      final veterinario =
          vacuna['veterinario']?.toString().trim() ?? '';

      eventos.add({
        'origen': 'vacuna',
        'tipo': 'Vacuna',
        'titulo': nombreVacuna.isNotEmpty
            ? 'Vacuna: $nombreVacuna'
            : 'Vacuna',
        'mascota': mascota.nombre,
        'veterinario': veterinario,
        'fecha': fecha,
        'hora': '',
      });
    }

    // ----------------------------------------------------------
    // DESPARASITACIONES
    //
    // AHORA USAMOS fecha_aplicacion
    // ----------------------------------------------------------

    for (final desparasitacion in _desparasitaciones) {
      final fechaTexto =
          desparasitacion['fecha_aplicacion']
                  ?.toString()
                  .trim() ??
              '';

      if (fechaTexto.isEmpty) {
        continue;
      }

      final fecha = _convertirFecha(fechaTexto);

      if (fecha == null) {
        continue;
      }

      // Solo hoy o fechas futuras.
      if (_fechaSinHora(fecha).isBefore(hoy)) {
        continue;
      }

      final petId =
          desparasitacion['pet_id']?.toString().trim() ?? '';

      final mascota = _buscarMascotaPorId(petId);

      if (mascota == null) {
        continue;
      }

      final tipo =
          desparasitacion['tipo']?.toString().trim() ?? '';

      final veterinario =
          desparasitacion['veterinario']
                  ?.toString()
                  .trim() ??
              '';

      eventos.add({
        'origen': 'desparasitacion',
        'tipo': 'Desparasitación',
        'titulo': tipo.isNotEmpty
            ? 'Desparasitación: $tipo'
            : 'Desparasitación',
        'mascota': mascota.nombre,
        'veterinario': veterinario,
        'fecha': fecha,
        'hora': '',
      });
    }

    // ----------------------------------------------------------
    // FILTRAR POR MASCOTA ACTIVA
    // ----------------------------------------------------------

    final mascotaActiva = _mascotaActiva;

    var eventosFiltrados = eventos;

    if (mascotaActiva != null) {
      eventosFiltrados = eventos.where((evento) {
        final nombreMascota =
            evento['mascota']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        return nombreMascota ==
            mascotaActiva.nombre.trim().toLowerCase();
      }).toList();
    }

    // ----------------------------------------------------------
    // ORDENAR CRONOLÓGICAMENTE
    // ----------------------------------------------------------

    eventosFiltrados.sort((a, b) {
      final fechaA = a['fecha'] as DateTime;
      final fechaB = b['fecha'] as DateTime;

      final comparacionFecha =
          fechaA.compareTo(fechaB);

      if (comparacionFecha != 0) {
        return comparacionFecha;
      }

      final horaA =
          a['hora']?.toString() ?? '';

      final horaB =
          b['hora']?.toString() ?? '';

      return horaA.compareTo(horaB);
    });

    // Mostramos como máximo 4 eventos en Inicio.
    return eventosFiltrados.take(4).toList();
  }

  // ============================================================
  // FORMATEAR FECHA PARA LA TARJETA
  // ============================================================

  String _formatearFechaEvento(DateTime fecha) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    final hoy = _fechaSinHora(DateTime.now());

    final manana = hoy.add(
      const Duration(days: 1),
    );

    final fechaEvento = _fechaSinHora(fecha);

    if (fechaEvento.isAtSameMomentAs(hoy)) {
      return 'Hoy';
    }

    if (fechaEvento.isAtSameMomentAs(manana)) {
      return 'Mañana';
    }

    return '${fecha.day} ${meses[fecha.month - 1]}';
  }

  // ============================================================
  // ICONOS
  // ============================================================

  IconData _iconoEvento(String tipo) {
    switch (tipo) {
      case 'Vacuna':
        return Icons.vaccines;

      case 'Desparasitación':
        return Icons.medical_services_outlined;

      case 'Cita veterinaria':
        return Icons.calendar_month;

      default:
        return Icons.notifications_active_outlined;
    }
  }

  // ============================================================
  // COLORES
  // ============================================================

  Color _colorEvento(String tipo) {
    switch (tipo) {
      case 'Vacuna':
        return Colors.teal;

      case 'Desparasitación':
        return Colors.orange.shade700;

      case 'Cita veterinaria':
        return Colors.blue.shade700;

      default:
        return Colors.purple.shade600;
    }
  }

  // ============================================================
  // TARJETA MASCOTA ACTIVA
  // ============================================================

  Widget _construirMascotaActiva() {
    if (_mascotas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets,
                size: 35,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Aún no tienes mascotas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Registra tu primera mascota para comenzar a organizar sus cuidados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _abrirMascotas,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Agregar mascota',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final mascota = _mascotaActiva!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              size: 34,
              color: Colors.teal.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mascota.nombre,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${mascota.especie} · ${mascota.raza}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${mascota.edad} '
                  '${mascota.edad == 1 ? 'año' : 'años'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Cambiar mascota',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.teal.shade700,
              ),
            ),
            onSelected: (id) {
              setState(() {
                _mascotaActivaId = id;
              });
            },
            itemBuilder: (context) {
              return _mascotas.map((pet) {
                final seleccionada =
                    pet.id == _mascotaActivaId;

                return PopupMenuItem<String>(
                  value: pet.id,
                  child: Row(
                    children: [
                      Icon(
                        Icons.pets,
                        size: 20,
                        color: seleccionada
                            ? Colors.teal
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pet.nombre,
                          style: TextStyle(
                            fontWeight: seleccionada
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (seleccionada)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.teal,
                          size: 20,
                        ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TARJETA DE EVENTO
  // ============================================================

  Widget _construirEvento(
    Map<String, dynamic> evento,
  ) {
    final tipo =
        evento['tipo']?.toString() ?? 'Otro';

    final titulo =
        evento['titulo']?.toString() ?? 'Evento';

    final mascota =
        evento['mascota']?.toString() ?? '';

    final veterinario =
        evento['veterinario']?.toString() ?? '';

    final hora =
        evento['hora']?.toString() ?? '';

    final fecha =
        evento['fecha'] as DateTime;

    final color = _colorEvento(tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () {
          if (evento['origen'] == 'cita') {
            _abrirCitas();
          } else {
            _abrirAgenda();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconoEvento(tipo),
                  color: color,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mascota,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    if (veterinario.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        veterinario,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatearFechaEvento(fecha),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (hora.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      hora,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRÓXIMOS EVENTOS
  // ============================================================

  Widget _construirProximosEventos() {
    final eventos = _obtenerProximosEventos();

    if (_mascotas.isEmpty) {
      return const SizedBox.shrink();
    }

    if (eventos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.teal.shade100,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 46,
              color: Colors.teal.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay eventos próximos',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _mascotaActiva == null
                  ? 'No tienes actividades pendientes.'
                  : '${_mascotaActiva!.nombre} no tiene actividades próximas.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: eventos
          .map(
            (evento) => _construirEvento(evento),
          )
          .toList(),
    );
  }

  // ============================================================
  // INICIO
  // ============================================================

  Widget _construirInicio() {
    return RefreshIndicator(
      color: Colors.teal,
      onRefresh: _cargarDatos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          22,
          20,
          120,
        ),
        children: [
          const Text(
            '¡Hola! 👋',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aquí tienes el resumen del cuidado de tus mascotas.',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Icon(
                Icons.pets,
                size: 20,
                color: Colors.teal.shade700,
              ),
              const SizedBox(width: 8),
              const Text(
                'MASCOTA ACTIVA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF455A64),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _construirMascotaActiva(),
          const SizedBox(height: 30),
          if (_mascotas.isNotEmpty) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Próximos eventos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _abrirAgenda,
                  child: Text(
                    'Ver agenda',
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _construirProximosEventos(),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _abrirCitas,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal.shade700,
                side: BorderSide(
                  color: Colors.teal.shade200,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(
                Icons.calendar_month_outlined,
              ),
              label: const Text(
                'Gestionar citas veterinarias',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BARRA INFERIOR
  // ============================================================

  Widget _construirBarraInferior() {
    return NavigationBar(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: Colors.teal.shade100,
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            break;

          case 1:
            _abrirMascotas();
            break;

          case 2:
            _abrirAgenda();
            break;

          case 3:
            _abrirPerfil();
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(
            Icons.home_outlined,
          ),
          selectedIcon: Icon(
            Icons.home,
            color: Colors.teal,
          ),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.pets_outlined,
          ),
          selectedIcon: Icon(
            Icons.pets,
            color: Colors.teal,
          ),
          label: 'Mascotas',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.calendar_month_outlined,
          ),
          selectedIcon: Icon(
            Icons.calendar_month,
            color: Colors.teal,
          ),
          label: 'Agenda',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.person_outline,
          ),
          selectedIcon: Icon(
            Icons.person,
            color: Colors.teal,
          ),
          label: 'Perfil',
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets,
              size: 24,
            ),
            SizedBox(width: 9),
            Text(
              'PetCare',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Salir',
            onPressed: _cerrarSesion,
            icon: const Icon(
              Icons.logout,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.teal,
              ),
            )
          : _construirInicio(),
      bottomNavigationBar: _construirBarraInferior(),
    );
  }
}
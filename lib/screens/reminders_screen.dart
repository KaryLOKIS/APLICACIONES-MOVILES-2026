import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../services/database_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;

  List<Pet> _mascotas = [];
  List<_EventoAgenda> _eventos = [];

  bool _cargando = true;
  String _filtroSeleccionado = 'Todos';

  final List<String> _filtros = const [
    'Todos',
    'Vacunas',
    'Desparasitación',
    'Citas',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // =========================================================
  // CARGAR DATOS DE LA AGENDA
  // =========================================================

  Future<void> _cargarDatos() async {
    if (mounted) {
      setState(() {
        _cargando = true;
      });
    }

    try {
      final resultados = await Future.wait([
        _databaseService.obtenerMascotas(),
        _databaseService.obtenerCitasVeterinarias(),
        _databaseService.obtenerTodasLasVacunas(),
        _databaseService.obtenerTodasLasDesparasitaciones(),
      ]);

      final mascotas = (resultados[0] as List<Pet>)
          .where((mascota) => !mascota.deleted)
          .toList();

      final citas =
          resultados[1] as List<Map<String, dynamic>>;

      final vacunas =
          resultados[2] as List<Map<String, dynamic>>;

      final desparasitaciones =
          resultados[3] as List<Map<String, dynamic>>;

      final eventos = <_EventoAgenda>[];

      final hoy = _fechaSinHora(DateTime.now());

      // =====================================================
      // CITAS VETERINARIAS
      // =====================================================

      for (final cita in citas) {
        final fecha = _convertirFecha(
          cita['fecha'],
        );

        if (fecha == null) {
          continue;
        }

        final fechaEvento = _fechaSinHora(fecha);

        // Solo hoy y fechas futuras.
        if (fechaEvento.isBefore(hoy)) {
          continue;
        }

        final motivo =
            cita['motivo']?.toString().trim() ?? '';

        final mascota =
            cita['mascota']?.toString().trim() ?? '';

        final veterinario =
            cita['veterinario']?.toString().trim() ?? '';

        final hora =
            cita['hora']?.toString().trim() ?? '';

        eventos.add(
          _EventoAgenda(
            tipo: 'Cita',
            titulo: motivo.isEmpty
                ? 'Cita veterinaria'
                : motivo,
            mascota: mascota.isEmpty
                ? 'Mascota'
                : mascota,
            veterinario: veterinario,
            fecha: fechaEvento,
            hora: hora.isEmpty ? null : hora,
          ),
        );
      }

      // =====================================================
      // VACUNAS
      //
      // IMPORTANTE:
      // Se usa fecha_aplicacion.
      // Ya NO se utiliza proxima_dosis.
      // =====================================================

      for (final vacuna in vacunas) {
        final fecha = _convertirFecha(
          vacuna['fecha_aplicacion'],
        );

        if (fecha == null) {
          continue;
        }

        final fechaEvento = _fechaSinHora(fecha);

        if (fechaEvento.isBefore(hoy)) {
          continue;
        }

        final nombreVacuna =
            vacuna['vacuna']?.toString().trim() ?? '';

        final petId =
            vacuna['pet_id']?.toString().trim() ?? '';

        final veterinario =
            vacuna['veterinario']?.toString().trim() ?? '';

        eventos.add(
          _EventoAgenda(
            tipo: 'Vacuna',
            titulo: nombreVacuna.isEmpty
                ? 'Vacuna'
                : 'Vacuna: $nombreVacuna',
            mascota: _buscarNombreMascota(
              petId,
              mascotas,
            ),
            veterinario: veterinario,
            fecha: fechaEvento,
          ),
        );
      }

      // =====================================================
      // DESPARASITACIONES
      //
      // IMPORTANTE:
      // Se usa fecha_aplicacion.
      // Ya NO se utiliza proxima_dosis.
      // =====================================================

      for (final desparasitacion in desparasitaciones) {
        final fecha = _convertirFecha(
          desparasitacion['fecha_aplicacion'],
        );

        if (fecha == null) {
          continue;
        }

        final fechaEvento = _fechaSinHora(fecha);

        if (fechaEvento.isBefore(hoy)) {
          continue;
        }

        final producto =
            desparasitacion['tipo']?.toString().trim() ?? '';

        final petId =
            desparasitacion['pet_id']?.toString().trim() ?? '';

        final veterinario =
            desparasitacion['veterinario']
                    ?.toString()
                    .trim() ??
                '';

        eventos.add(
          _EventoAgenda(
            tipo: 'Desparasitación',
            titulo: producto.isEmpty
                ? 'Desparasitación'
                : 'Desparasitación: $producto',
            mascota: _buscarNombreMascota(
              petId,
              mascotas,
            ),
            veterinario: veterinario,
            fecha: fechaEvento,
          ),
        );
      }

      // =====================================================
      // ORDEN CRONOLÓGICO
      // =====================================================

      eventos.sort((a, b) {
        final comparacionFecha =
            a.fecha.compareTo(b.fecha);

        if (comparacionFecha != 0) {
          return comparacionFecha;
        }

        // Si hay varios eventos el mismo día,
        // las citas con hora se organizan primero.
        if (a.tipo == 'Cita' && b.tipo != 'Cita') {
          return -1;
        }

        if (b.tipo == 'Cita' && a.tipo != 'Cita') {
          return 1;
        }

        return (a.hora ?? '').compareTo(
          b.hora ?? '',
        );
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _mascotas = mascotas;
        _eventos = eventos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo cargar la agenda: $e',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // =========================================================
  // BUSCAR NOMBRE DE MASCOTA POR ID
  // =========================================================

  String _buscarNombreMascota(
    String petId,
    List<Pet> mascotas,
  ) {
    if (petId.isEmpty) {
      return 'Mascota';
    }

    for (final mascota in mascotas) {
      if (mascota.id == petId) {
        return mascota.nombre;
      }
    }

    return 'Mascota';
  }

  // =========================================================
  // CONVERTIR FECHAS
  //
  // SOPORTA:
  // DD/MM/YYYY
  // YYYY-MM-DD
  // YYYY-MM-DDTHH:mm:ss.sss
  // =========================================================

  DateTime? _convertirFecha(dynamic valor) {
    try {
      final texto =
          valor?.toString().trim() ?? '';

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
      final fechaIso =
          DateTime.tryParse(texto);

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

  // =========================================================
  // FORMATO DE FECHA
  // =========================================================

  String _formatearFecha(DateTime fecha) {
    final dia =
        fecha.day.toString().padLeft(2, '0');

    final mes =
        fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

  // =========================================================
  // NOMBRE DEL DÍA
  // =========================================================

  String _nombreDia(DateTime fecha) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    return dias[fecha.weekday - 1];
  }

  // =========================================================
  // NOMBRE DEL MES
  // =========================================================

  String _nombreMesCorto(int mes) {
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

    return meses[mes - 1];
  }

  // =========================================================
  // FILTROS
  // =========================================================

  List<_EventoAgenda> get _eventosFiltrados {
    switch (_filtroSeleccionado) {
      case 'Vacunas':
        return _eventos
            .where(
              (evento) =>
                  evento.tipo == 'Vacuna',
            )
            .toList();

      case 'Desparasitación':
        return _eventos
            .where(
              (evento) =>
                  evento.tipo ==
                  'Desparasitación',
            )
            .toList();

      case 'Citas':
        return _eventos
            .where(
              (evento) =>
                  evento.tipo == 'Cita',
            )
            .toList();

      default:
        return _eventos;
    }
  }

  // =========================================================
  // ICONO POR TIPO
  // =========================================================

  IconData _iconoEvento(String tipo) {
    switch (tipo) {
      case 'Vacuna':
        return Icons.vaccines_outlined;

      case 'Desparasitación':
        return Icons.medication_outlined;

      case 'Cita':
        return Icons.medical_services_outlined;

      default:
        return Icons.event_outlined;
    }
  }

  // =========================================================
  // COLOR POR TIPO
  // =========================================================

  Color _colorEvento(String tipo) {
    switch (tipo) {
      case 'Vacuna':
        return Colors.teal;

      case 'Desparasitación':
        return Colors.orange.shade700;

      case 'Cita':
        return Colors.blue.shade700;

      default:
        return Colors.grey.shade700;
    }
  }

  Color _fondoEvento(String tipo) {
    switch (tipo) {
      case 'Vacuna':
        return Colors.teal.shade50;

      case 'Desparasitación':
        return Colors.orange.shade50;

      case 'Cita':
        return Colors.blue.shade50;

      default:
        return Colors.grey.shade100;
    }
  }

  // =========================================================
  // ESTADO DEL EVENTO
  // =========================================================

  String _estadoEvento(DateTime fecha) {
    final hoy =
        _fechaSinHora(DateTime.now());

    final evento =
        _fechaSinHora(fecha);

    if (evento == hoy) {
      return 'HOY';
    }

    if (evento ==
        hoy.add(const Duration(days: 1))) {
      return 'MAÑANA';
    }

    return 'PRÓXIMO';
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'HOY':
        return Colors.red.shade600;

      case 'MAÑANA':
        return Colors.orange.shade700;

      default:
        return Colors.teal.shade700;
    }
  }

  // =========================================================
  // CABECERA DE LA AGENDA
  // =========================================================

  Widget _construirCabecera() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade700,
            Colors.teal.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tus próximos eventos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Consulta en un solo lugar las próximas '
            'vacunas, desparasitaciones y citas '
            'veterinarias de tus mascotas.',
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.90,
              ),
              fontSize: 14,
              height: 1.4,
            ),
          ),

          if (_mascotas.isNotEmpty) ...[
            const SizedBox(height: 16),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.16,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Text(
                '${_mascotas.length} '
                '${_mascotas.length == 1 ? 'mascota' : 'mascotas'} '
                'registradas',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // FILTROS
  // =========================================================

  Widget _construirFiltros() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        itemCount: _filtros.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtro = _filtros[index];

          final seleccionado =
              _filtroSeleccionado ==
                  filtro;

          return ChoiceChip(
            label: Text(filtro),
            selected: seleccionado,
            showCheckmark: false,
            avatar: Icon(
              _iconoFiltro(filtro),
              size: 18,
              color: seleccionado
                  ? Colors.white
                  : Colors.teal.shade700,
            ),
            labelStyle: TextStyle(
              color: seleccionado
                  ? Colors.white
                  : Colors.teal.shade800,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: Colors.teal,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: seleccionado
                  ? Colors.teal
                  : Colors.teal.shade100,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),
            onSelected: (_) {
              setState(() {
                _filtroSeleccionado =
                    filtro;
              });
            },
          );
        },
      ),
    );
  }

  IconData _iconoFiltro(String filtro) {
    switch (filtro) {
      case 'Vacunas':
        return Icons.vaccines_outlined;

      case 'Desparasitación':
        return Icons.medication_outlined;

      case 'Citas':
        return Icons.medical_services_outlined;

      default:
        return Icons.dashboard_outlined;
    }
  }

  // =========================================================
  // TARJETA DE EVENTO
  // =========================================================

  Widget _construirEvento(
    _EventoAgenda evento,
  ) {
    final color =
        _colorEvento(evento.tipo);

    final fondo =
        _fondoEvento(evento.tipo);

    final estado =
        _estadoEvento(evento.fecha);

    return Container(
      margin:
          const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ===============================================
            // FECHA
            // ===============================================

            Container(
              width: 62,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: fondo,
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(
                    alpha: 0.18,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    evento.fecha.day
                        .toString()
                        .padLeft(2, '0'),
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  Text(
                    _nombreMesCorto(
                      evento.fecha.month,
                    ).toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // ===============================================
            // INFORMACIÓN
            // ===============================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration:
                            BoxDecoration(
                          color: fondo,
                          shape:
                              BoxShape.circle,
                        ),
                        child: Icon(
                          _iconoEvento(
                            evento.tipo,
                          ),
                          color: color,
                          size: 19,
                        ),
                      ),

                      const SizedBox(
                        width: 9,
                      ),

                      Expanded(
                        child: Text(
                          evento.titulo,
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Colors.black87,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(
                        Icons.pets_outlined,
                        size: 18,
                        color: Colors
                            .grey.shade600,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          evento.mascota,
                          style: TextStyle(
                            color: Colors
                                .grey.shade800,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      Icon(
                        Icons
                            .calendar_today_outlined,
                        size: 17,
                        color: Colors
                            .grey.shade600,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '${_nombreDia(evento.fecha)}, '
                          '${_formatearFecha(evento.fecha)}',
                          style: TextStyle(
                            color: Colors
                                .grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (evento.hora != null &&
                      evento.hora!
                          .isNotEmpty) ...[
                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Icon(
                          Icons
                              .access_time_outlined,
                          size: 18,
                          color: Colors
                              .grey.shade600,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          evento.hora!,
                          style: TextStyle(
                            color: Colors
                                .grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (evento.veterinario
                      .isNotEmpty) ...[
                    const SizedBox(height: 7),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Icon(
                          Icons
                              .medical_services_outlined,
                          size: 18,
                          color: Colors
                              .grey.shade600,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            evento
                                .veterinario,
                            style: TextStyle(
                              color: Colors
                                  .grey
                                  .shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 11),

                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color: fondo,
                          borderRadius:
                              BorderRadius
                                  .circular(10),
                        ),
                        child: Text(
                          evento.tipo
                              .toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 7),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color: _colorEstado(
                            estado,
                          ).withValues(
                            alpha: 0.10,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(10),
                        ),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color:
                                _colorEstado(
                              estado,
                            ),
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ESTADO VACÍO
  // =========================================================

  Widget _construirEstadoVacio() {
    String titulo;
    String descripcion;
    IconData icono;

    switch (_filtroSeleccionado) {
      case 'Vacunas':
        titulo =
            'No hay vacunas programadas';
        descripcion =
            'Las vacunas con fecha de aplicación '
            'de hoy en adelante aparecerán '
            'automáticamente aquí.';
        icono =
            Icons.vaccines_outlined;
        break;

      case 'Desparasitación':
        titulo =
            'No hay desparasitaciones programadas';
        descripcion =
            'Las desparasitaciones con fecha de '
            'aplicación de hoy en adelante '
            'aparecerán automáticamente aquí.';
        icono =
            Icons.medication_outlined;
        break;

      case 'Citas':
        titulo =
            'No hay próximas citas';
        descripcion =
            'Las citas veterinarias programadas '
            'aparecerán automáticamente aquí.';
        icono =
            Icons.medical_services_outlined;
        break;

      default:
        titulo =
            'Tu agenda está al día';
        descripcion =
            'No tienes vacunas, '
            'desparasitaciones o citas '
            'veterinarias programadas.';
        icono =
            Icons.event_available_outlined;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        42,
        24,
        40,
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icono,
              size: 48,
              color: Colors.teal.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            descripcion,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final eventos =
        _eventosFiltrados;

    return Scaffold(
      backgroundColor:
          Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Agenda',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed:
                _cargando
                    ? null
                    : _cargarDatos,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: Colors.teal,
              ),
            )
          : RefreshIndicator(
              color: Colors.teal,
              onRefresh: _cargarDatos,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _construirCabecera(),

                  const SizedBox(height: 20),

                  _construirFiltros(),

                  const SizedBox(height: 16),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _filtroSeleccionado ==
                                    'Todos'
                                ? 'Próximos eventos'
                                : _filtroSeleccionado,
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Colors.black87,
                            ),
                          ),
                        ),

                        if (eventos.isNotEmpty)
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            child: Text(
                              '${eventos.length}',
                              style: TextStyle(
                                color: Colors
                                    .teal
                                    .shade700,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (eventos.isEmpty)
                    _construirEstadoVacio()
                  else
                    Padding(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        16,
                        0,
                        16,
                        30,
                      ),
                      child: Column(
                        children: eventos
                            .map(
                              _construirEvento,
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ===========================================================
// MODELO INTERNO DEL EVENTO
// ===========================================================

class _EventoAgenda {
  const _EventoAgenda({
    required this.tipo,
    required this.titulo,
    required this.mascota,
    required this.veterinario,
    required this.fecha,
    this.hora,
  });

  final String tipo;
  final String titulo;
  final String mascota;
  final String veterinario;
  final DateTime fecha;
  final String? hora;
}
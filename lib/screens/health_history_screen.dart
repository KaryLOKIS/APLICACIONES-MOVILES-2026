import 'package:flutter/material.dart';

import '../services/database_service.dart';

class HealthHistoryScreen extends StatefulWidget {
  final String petId;
  final String petName;
  final String especie;
  final String raza;

  const HealthHistoryScreen({
    super.key,
    required this.petId,
    required this.petName,
    required this.especie,
    required this.raza,
  });

  @override
  State<HealthHistoryScreen> createState() =>
      _HealthHistoryScreenState();
}

class _HealthHistoryScreenState
    extends State<HealthHistoryScreen> {
  final DatabaseService _databaseService =
      DatabaseService.instance;

  bool _cargando = true;

  List<Map<String, dynamic>> _consultas = [];
  List<_EventoSalud> _eventos = [];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  // =========================================================
  // CARGAR HISTORIAL
  // =========================================================

  Future<void> _cargarHistorial() async {
    try {
      final vacunas =
          await _databaseService.obtenerVacunasPorMascota(
        widget.petId,
      );

      final desparasitaciones =
          await _databaseService
              .obtenerDesparasitacionesPorMascota(
        widget.petId,
      );

      final todasLasCitas =
          await _databaseService.obtenerCitasVeterinarias();

      final ahora = DateTime.now();

      final hoy = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
      );

      // =====================================================
      // CONSULTAS DE ESTA MASCOTA QUE YA OCURRIERON
      // =====================================================

      final consultas = todasLasCitas.where((cita) {
        final mascota =
            cita['mascota']?.toString().trim() ?? '';

        if (mascota.toLowerCase() !=
            widget.petName.trim().toLowerCase()) {
          return false;
        }

        final fecha =
            cita['fecha']?.toString() ?? '';

        final hora =
            cita['hora']?.toString() ?? '00:00';

        final fechaHora =
            _convertirFechaHora(fecha, hora);

        if (fechaHora == null) {
          return false;
        }

        return !fechaHora.isAfter(ahora);
      }).toList();

      final eventos = <_EventoSalud>[];

      // =====================================================
      // VACUNAS YA APLICADAS
      // =====================================================

      for (final vacuna in vacunas) {
        final fechaTexto =
            vacuna['fecha_aplicacion']
                    ?.toString() ??
                '';

        final fecha =
            DateTime.tryParse(fechaTexto);

        if (fecha == null) {
          continue;
        }

        final fechaVacuna = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
        );

        // Si la vacuna está programada para una fecha futura,
        // todavía no pertenece al historial.
        if (fechaVacuna.isAfter(hoy)) {
          continue;
        }

        eventos.add(
          _EventoSalud(
            tipo: _TipoEventoSalud.vacuna,
            titulo:
                'Vacuna: ${vacuna['vacuna']?.toString() ?? 'Vacuna'}',
            fecha: fechaVacuna,
            veterinario:
                vacuna['veterinario']
                        ?.toString() ??
                    '',
            observaciones:
                vacuna['observaciones']
                        ?.toString() ??
                    '',
          ),
        );
      }

      // =====================================================
      // DESPARASITACIONES YA REALIZADAS
      // =====================================================

      for (final desparasitacion
          in desparasitaciones) {
        final fechaTexto =
            desparasitacion['fecha_aplicacion']
                    ?.toString() ??
                '';

        final fecha =
            DateTime.tryParse(fechaTexto);

        if (fecha == null) {
          continue;
        }

        final fechaDesparasitacion = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
        );

        // Las desparasitaciones futuras permanecen en Agenda.
        if (fechaDesparasitacion.isAfter(hoy)) {
          continue;
        }

        eventos.add(
          _EventoSalud(
            tipo:
                _TipoEventoSalud.desparasitacion,
            titulo:
                'Desparasitación: ${desparasitacion['tipo']?.toString() ?? 'Tratamiento'}',
            fecha: fechaDesparasitacion,
            veterinario:
                desparasitacion['veterinario']
                        ?.toString() ??
                    '',
            observaciones:
                desparasitacion['observaciones']
                        ?.toString() ??
                    '',
          ),
        );
      }

      // =====================================================
      // CONSULTAS VETERINARIAS YA REALIZADAS
      // =====================================================

      for (final consulta in consultas) {
        final fecha =
            consulta['fecha']?.toString() ?? '';

        final hora =
            consulta['hora']?.toString() ?? '';

        final fechaHora =
            _convertirFechaHora(fecha, hora);

        if (fechaHora == null) {
          continue;
        }

        eventos.add(
          _EventoSalud(
            tipo: _TipoEventoSalud.consulta,
            titulo:
                consulta['motivo']?.toString() ??
                    'Consulta veterinaria',
            fecha: fechaHora,
            veterinario:
                consulta['veterinario']
                        ?.toString() ??
                    '',
            hora: hora,
          ),
        );
      }

      // Más reciente primero.
      eventos.sort(
        (a, b) => b.fecha.compareTo(a.fecha),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _consultas = consultas;
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
          backgroundColor: Colors.red.shade700,
          content: Text(
            'No se pudo cargar el historial de salud: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // CONVERTIR FECHA Y HORA
  // =========================================================

  DateTime? _convertirFechaHora(
    String fecha,
    String hora,
  ) {
    try {
      final partesFecha = fecha.split('-');

      if (partesFecha.length != 3) {
        return null;
      }

      final partesHora = hora.split(':');

      final year =
          int.tryParse(partesFecha[0]);

      final month =
          int.tryParse(partesFecha[1]);

      final day =
          int.tryParse(partesFecha[2]);

      final hour = partesHora.isNotEmpty
          ? int.tryParse(partesHora[0])
          : 0;

      final minute = partesHora.length > 1
          ? int.tryParse(partesHora[1])
          : 0;

      if (year == null ||
          month == null ||
          day == null) {
        return null;
      }

      return DateTime(
        year,
        month,
        day,
        hour ?? 0,
        minute ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // FORMATO DE FECHA
  // =========================================================

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  // =========================================================
  // CONTADORES
  // =========================================================

  int get _cantidadVacunas {
    return _eventos
        .where(
          (evento) =>
              evento.tipo ==
              _TipoEventoSalud.vacuna,
        )
        .length;
  }

  int get _cantidadDesparasitaciones {
    return _eventos
        .where(
          (evento) =>
              evento.tipo ==
              _TipoEventoSalud.desparasitacion,
        )
        .length;
  }

  int get _cantidadConsultas {
    return _eventos
        .where(
          (evento) =>
              evento.tipo ==
              _TipoEventoSalud.consulta,
        )
        .length;
  }

  // =========================================================
  // CABECERA DE LA MASCOTA
  // =========================================================

  Widget _crearCabeceraMascota() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              color: Colors.teal.shade700,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.petName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.especie} · ${widget.raza}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      size: 16,
                      color: Colors.teal.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Historial médico',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RESUMEN
  // =========================================================

  Widget _crearResumen() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen de salud',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _tarjetaResumen(
                icono: Icons.vaccines,
                cantidad: _cantidadVacunas,
                titulo: 'Vacunas',
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tarjetaResumen(
                icono:
                    Icons.medical_services_outlined,
                cantidad:
                    _cantidadDesparasitaciones,
                titulo: 'Desparasit.',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tarjetaResumen(
                icono:
                    Icons.local_hospital_outlined,
                cantidad: _cantidadConsultas,
                titulo: 'Consultas',
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tarjetaResumen({
    required IconData icono,
    required int cantidad,
    required String titulo,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icono,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cantidad.toString(),
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TARJETA DE EVENTO
  // =========================================================

  Widget _crearTarjetaEvento(
    _EventoSalud evento,
  ) {
    IconData icono;
    Color color;
    String tipo;

    switch (evento.tipo) {
      case _TipoEventoSalud.vacuna:
        icono = Icons.vaccines;
        color = Colors.teal;
        tipo = 'VACUNA';
        break;

      case _TipoEventoSalud.desparasitacion:
        icono =
            Icons.medical_services_outlined;
        color = Colors.orange;
        tipo = 'DESPARASITACIÓN';
        break;

      case _TipoEventoSalud.consulta:
        icono =
            Icons.local_hospital_outlined;
        color = Colors.blue;
        tipo = 'CONSULTA';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    color.withValues(alpha: 0.10),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                icono,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    tipo,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    evento.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 16,
                        color:
                            Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatearFecha(
                          evento.fecha,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                      if (evento.hora != null &&
                          evento.hora!
                              .isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color:
                              Colors.grey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          evento.hora!,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (evento.veterinario
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 17,
                          color:
                              Colors.teal.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            evento.veterinario,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (evento.observaciones
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            Colors.grey.shade50,
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                      child: Text(
                        evento.observaciones,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HISTORIAL VACÍO
  // =========================================================

  Widget _crearHistorialVacio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
              Icons.health_and_safety_outlined,
              size: 35,
              color: Colors.teal.shade500,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Aún no hay historial médico',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Las vacunas, desparasitaciones y consultas realizadas aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.grey.shade600,
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
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Historial de salud',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.teal,
              ),
            )
          : RefreshIndicator(
              color: Colors.teal,
              onRefresh: _cargarHistorial,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  30,
                ),
                children: [
                  _crearCabeceraMascota(),
                  const SizedBox(height: 24),
                  _crearResumen(),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Historial médico',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFF263238),
                          ),
                        ),
                      ),
                      if (_eventos.isNotEmpty)
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
                                Colors.teal.shade100,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Text(
                            '${_eventos.length} registros',
                            style: TextStyle(
                              color:
                                  Colors.teal.shade800,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  if (_eventos.isEmpty)
                    _crearHistorialVacio()
                  else
                    ..._eventos.map(
                      _crearTarjetaEvento,
                    ),
                ],
              ),
            ),
    );
  }
}

// ===========================================================
// MODELO INTERNO PARA UNIFICAR EL HISTORIAL
// ===========================================================

enum _TipoEventoSalud {
  vacuna,
  desparasitacion,
  consulta,
}

class _EventoSalud {
  final _TipoEventoSalud tipo;
  final String titulo;
  final DateTime fecha;
  final String veterinario;
  final String observaciones;
  final String? hora;

  const _EventoSalud({
    required this.tipo,
    required this.titulo,
    required this.fecha,
    required this.veterinario,
    this.observaciones = '',
    this.hora,
  });
}
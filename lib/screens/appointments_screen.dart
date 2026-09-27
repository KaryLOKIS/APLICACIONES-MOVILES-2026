import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../services/database_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() =>
      _AppointmentsScreenState();
}

class _AppointmentsScreenState
    extends State<AppointmentsScreen> {
  final DatabaseService _databaseService =
      DatabaseService.instance;

  List<Map<String, dynamic>> _citas = [];
  List<Pet> _mascotas = [];
  List<Map<String, dynamic>> _veterinarios = [];

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // =========================================================
  // CARGAR CITAS, MASCOTAS Y VETERINARIOS
  // =========================================================

  Future<void> _cargarDatos() async {
    try {
      final citas =
          await _databaseService.obtenerCitasVeterinarias();

      final mascotas =
          await _databaseService.obtenerMascotas();

      final veterinarios =
          await _databaseService.obtenerVeterinarios();

      if (!mounted) {
        return;
      }

      setState(() {
        _citas = citas;
        _mascotas = mascotas;
        _veterinarios = veterinarios;
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
            'No se pudieron cargar los datos: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // ABRIR FORMULARIO NUEVA CITA
  // =========================================================

  Future<void> _mostrarFormularioCita() async {
    if (_mascotas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade700,
          content: const Text(
            'Primero debes registrar al menos una mascota.',
          ),
        ),
      );

      return;
    }

    final resultado =
        await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _FormularioCitaDialog(
          mascotas: _mascotas,
          veterinarios: _veterinarios,
        );
      },
    );

    if (resultado == null) {
      return;
    }

    try {
      await _databaseService.insertarCitaVeterinaria(
        mascota: resultado['mascota'] as String,
        veterinario:
            resultado['veterinario'] as String,
        motivo: resultado['motivo'] as String,
        fecha: resultado['fecha'] as String,
        hora: resultado['hora'] as String,
      );

      await _cargarDatos();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.teal.shade700,
          content: const Text(
            'Cita veterinaria registrada correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'No se pudo guardar la cita: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // EDITAR CITA
  // =========================================================

  Future<void> _editarCita(
    Map<String, dynamic> cita,
  ) async {
    if (_mascotas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade700,
          content: const Text(
            'No hay mascotas disponibles.',
          ),
        ),
      );

      return;
    }

    final resultado =
        await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _FormularioCitaDialog(
          mascotas: _mascotas,
          veterinarios: _veterinarios,
          cita: cita,
        );
      },
    );

    if (resultado == null) {
      return;
    }

    try {
      await _databaseService.actualizarCitaVeterinaria(
        id: cita['id'] as String,
        mascota: resultado['mascota'] as String,
        veterinario:
            resultado['veterinario'] as String,
        motivo: resultado['motivo'] as String,
        fecha: resultado['fecha'] as String,
        hora: resultado['hora'] as String,
      );

      await _cargarDatos();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.teal.shade700,
          content: const Text(
            'Cita veterinaria actualizada correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'No se pudo actualizar la cita: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // ELIMINAR CITA
  // =========================================================

  Future<void> _eliminarCita(
    Map<String, dynamic> cita,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Eliminar cita',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '¿Deseas eliminar la cita de '
            '${cita['mascota'] ?? 'la mascota'}?',
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
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await _databaseService.eliminarCitaVeterinaria(
        cita['id'] as String,
      );

      await _cargarDatos();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.teal.shade700,
          content: const Text(
            'Cita eliminada correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'No se pudo eliminar la cita: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // FORMATO DE FECHA
  // =========================================================

  String _formatearFecha(String fecha) {
    try {
      final partes = fecha.split('-');

      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }

      return fecha;
    } catch (_) {
      return fecha;
    }
  }

  // =========================================================
  // TARJETA DE CITA
  // =========================================================

  Widget _crearTarjetaCita(
    Map<String, dynamic> cita,
  ) {
    final mascota =
        cita['mascota']?.toString() ?? 'Sin mascota';

    final veterinario =
        cita['veterinario']?.toString() ??
            'Sin veterinario';

    final motivo =
        cita['motivo']?.toString() ??
            'Consulta veterinaria';

    final fecha =
        cita['fecha']?.toString() ?? '';

    final hora =
        cita['hora']?.toString() ?? '';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      color: Colors.white,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: Colors.teal.shade700,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        mascota,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        motivo,
                        style: TextStyle(
                          color:
                              Colors.teal.shade700,
                          fontWeight:
                              FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (opcion) {
                    if (opcion == 'editar') {
                      _editarCita(cita);
                    }

                    if (opcion == 'eliminar') {
                      _eliminarCita(cita);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color:
                                Colors.teal.shade700,
                          ),
                          const SizedBox(width: 10),
                          const Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            Divider(
              color: Colors.grey.shade200,
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 20,
                  color: Colors.teal.shade600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    veterinario,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 20,
                  color: Colors.teal.shade600,
                ),
                const SizedBox(width: 10),
                Text(
                  _formatearFecha(fecha),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 18),
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: Colors.teal.shade600,
                ),
                const SizedBox(width: 7),
                Text(
                  hora,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
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
          'Citas veterinarias',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.teal,
              ),
            )
          : _citas.isEmpty
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration:
                              const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            size: 45,
                            color:
                                Colors.teal.shade400,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'No tienes citas registradas',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFF263238),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Registra una cita para llevar '
                          'un mejor control de la salud '
                          'de tus mascotas.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: Colors.teal,
                  onRefresh: _cargarDatos,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(
                      14,
                      18,
                      14,
                      100,
                    ),
                    itemCount: _citas.length,
                    itemBuilder:
                        (context, index) {
                      return _crearTarjetaCita(
                        _citas[index],
                      );
                    },
                  ),
                ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _mostrarFormularioCita,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nueva cita',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// FORMULARIO DE CITA
// ===========================================================

class _FormularioCitaDialog
    extends StatefulWidget {
  const _FormularioCitaDialog({
    required this.mascotas,
    required this.veterinarios,
    this.cita,
  });

  final List<Pet> mascotas;

  final List<Map<String, dynamic>>
      veterinarios;

  final Map<String, dynamic>? cita;

  @override
  State<_FormularioCitaDialog>
      createState() =>
          _FormularioCitaDialogState();
}

class _FormularioCitaDialogState
    extends State<_FormularioCitaDialog> {
  final DatabaseService _databaseService =
      DatabaseService.instance;

  final TextEditingController
      _motivoController =
      TextEditingController();

  static const String _opcionAgregarVeterinario =
      '__AGREGAR_VETERINARIO__';

  String? _mascotaSeleccionada;

  String? _veterinarioSeleccionado;

  DateTime? _fechaSeleccionada;

  TimeOfDay? _horaSeleccionada;

  late List<Map<String, dynamic>>
      _veterinarios;

  bool get _esEdicion =>
      widget.cita != null;

  @override
  void initState() {
    super.initState();

    _veterinarios =
        widget.veterinarios
            .map(
              (vet) =>
                  Map<String, dynamic>.from(
                vet,
              ),
            )
            .toList();

    _cargarDatosEdicion();
  }

  // =========================================================
  // CARGAR DATOS SI ESTAMOS EDITANDO
  // =========================================================

  void _cargarDatosEdicion() {
    final cita = widget.cita;

    if (cita == null) {
      return;
    }

    final nombreMascota =
        cita['mascota']?.toString() ?? '';

    for (final pet in widget.mascotas) {
      if (pet.nombre == nombreMascota) {
        _mascotaSeleccionada = pet.id;
        break;
      }
    }

    final nombreVeterinario =
        cita['veterinario']?.toString() ?? '';

    for (final vet in _veterinarios) {
      if (vet['nombre']?.toString() ==
          nombreVeterinario) {
        _veterinarioSeleccionado =
            vet['id']?.toString();

        break;
      }
    }

    _motivoController.text =
        cita['motivo']?.toString() ?? '';

    final fechaTexto =
        cita['fecha']?.toString() ?? '';

    if (fechaTexto.isNotEmpty) {
      _fechaSeleccionada =
          DateTime.tryParse(fechaTexto);
    }

    final horaTexto =
        cita['hora']?.toString() ?? '';

    if (horaTexto.isNotEmpty) {
      final partes = horaTexto.split(':');

      if (partes.length >= 2) {
        final hora =
            int.tryParse(partes[0]);

        final minuto =
            int.tryParse(partes[1]);

        if (hora != null &&
            minuto != null) {
          _horaSeleccionada =
              TimeOfDay(
            hour: hora,
            minute: minuto,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();

    super.dispose();
  }

  // =========================================================
  // SELECCIONAR FECHA
  // =========================================================

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();

    DateTime fechaInicial =
        _fechaSeleccionada ?? ahora;

    DateTime fechaMinima =
        DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    );

    if (_esEdicion &&
        fechaInicial.isBefore(fechaMinima)) {
      fechaMinima = DateTime(
        fechaInicial.year,
        fechaInicial.month,
        fechaInicial.day,
      );
    }

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: fechaMinima,
      lastDate: DateTime(
        ahora.year + 5,
      ),
      builder: (context, child) {
        return Theme(
          data:
              Theme.of(context).copyWith(
            colorScheme:
                ColorScheme.fromSeed(
              seedColor: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  // =========================================================
  // SELECCIONAR HORA
  // =========================================================

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime:
          _horaSeleccionada ??
              TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data:
              Theme.of(context).copyWith(
            colorScheme:
                ColorScheme.fromSeed(
              seedColor: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (hora != null) {
      setState(() {
        _horaSeleccionada = hora;
      });
    }
  }

  // =========================================================
  // AGREGAR NUEVO VETERINARIO
  // =========================================================

  Future<void>
      _agregarNuevoVeterinario() async {
    final resultado =
        await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const _NuevoVeterinarioDialog();
      },
    );

    if (resultado == null) {
      return;
    }

    try {
      await _databaseService
          .insertarVeterinario(
        nombre:
            resultado['nombre'] ?? '',
        especialidad:
            resultado['especialidad'] ?? '',
        telefono:
            resultado['telefono'] ?? '',
        clinica:
            resultado['clinica'] ?? '',
      );

      final veterinarios =
          await _databaseService
              .obtenerVeterinarios();

      if (!mounted) {
        return;
      }

      String? idNuevoVeterinario;

      for (final veterinario
          in veterinarios) {
        final nombre =
            veterinario['nombre']
                    ?.toString() ??
                '';

        if (nombre ==
            resultado['nombre']) {
          idNuevoVeterinario =
              veterinario['id']
                  ?.toString();
        }
      }

      setState(() {
        _veterinarios =
            veterinarios;

        _veterinarioSeleccionado =
            idNuevoVeterinario;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
              Colors.teal.shade700,
          content: const Text(
            'Veterinario agregado correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _veterinarioSeleccionado =
            null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
              Colors.red.shade700,
          content: Text(
            'No se pudo agregar el veterinario: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // GUARDAR
  // =========================================================

  void _guardar() {
    if (_mascotaSeleccionada == null) {
      _mostrarMensaje(
        'Selecciona una mascota.',
      );

      return;
    }

    if (_veterinarioSeleccionado ==
            null ||
        _veterinarioSeleccionado ==
            _opcionAgregarVeterinario) {
      _mostrarMensaje(
        'Selecciona un veterinario.',
      );

      return;
    }

    if (_motivoController.text
        .trim()
        .isEmpty) {
      _mostrarMensaje(
        'Escribe el motivo de la cita.',
      );

      return;
    }

    if (_fechaSeleccionada == null) {
      _mostrarMensaje(
        'Selecciona la fecha de la cita.',
      );

      return;
    }

    if (_horaSeleccionada == null) {
      _mostrarMensaje(
        'Selecciona la hora de la cita.',
      );

      return;
    }

    final mascota =
        widget.mascotas.firstWhere(
      (pet) =>
          pet.id ==
          _mascotaSeleccionada,
    );

    final veterinario =
        _veterinarios.firstWhere(
      (vet) =>
          vet['id']?.toString() ==
          _veterinarioSeleccionado,
    );

    final fecha =
        _fechaSeleccionada!;

    final fechaTexto =
        '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';

    final hora =
        _horaSeleccionada!;

    final horaTexto =
        '${hora.hour.toString().padLeft(2, '0')}:'
        '${hora.minute.toString().padLeft(2, '0')}';

    Navigator.of(context).pop(
      {
        'mascota':
            mascota.nombre,

        'veterinario':
            veterinario['nombre']
                    ?.toString() ??
                '',

        'motivo':
            _motivoController.text
                .trim(),

        'fecha':
            fechaTexto,

        'hora':
            horaTexto,
      },
    );
  }

  void _mostrarMensaje(
    String mensaje,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
            Colors.orange.shade700,
        content: Text(mensaje),
      ),
    );
  }

  // =========================================================
  // FORMATO FECHA
  // =========================================================

  String _textoFecha() {
    if (_fechaSeleccionada == null) {
      return 'Seleccionar fecha';
    }

    final fecha =
        _fechaSeleccionada!;

    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  // =========================================================
  // BUILD DEL FORMULARIO
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(22),
      ),

      title: Row(
        children: [
          Icon(
            _esEdicion
                ? Icons.edit_calendar
                : Icons.calendar_month,
            color: Colors.teal.shade700,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _esEdicion
                  ? 'Editar cita veterinaria'
                  : 'Nueva cita veterinaria',
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),

      content:
          SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            // ===============================================
            // MASCOTA
            // ===============================================

            DropdownButtonFormField<String>(
              initialValue:
                  _mascotaSeleccionada,
              isExpanded: true,

              decoration:
                  InputDecoration(
                labelText: 'Mascota',

                prefixIcon: Icon(
                  Icons.pets,
                  color:
                      Colors.teal.shade700,
                ),

                filled: true,

                fillColor:
                    Colors.teal.shade50,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
              ),

              items:
                  widget.mascotas.map(
                (pet) {
                  return DropdownMenuItem<
                      String>(
                    value: pet.id,

                    child: Text(
                      '${pet.nombre} · ${pet.especie}',
                      maxLines: 1,
                      softWrap: false,
                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),
                  );
                },
              ).toList(),

              onChanged: (valor) {
                setState(() {
                  _mascotaSeleccionada =
                      valor;
                });
              },
            ),

            const SizedBox(height: 14),

            // ===============================================
            // VETERINARIO
            // ===============================================

            DropdownButtonFormField<String>(
              initialValue:
                  _veterinarioSeleccionado,

              isExpanded: true,

              decoration:
                  InputDecoration(
                labelText:
                    'Veterinario',

                prefixIcon: Icon(
                  Icons
                      .medical_services,
                  color:
                      Colors.teal.shade700,
                ),

                filled: true,

                fillColor:
                    Colors.teal.shade50,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
              ),

              items: [
                ..._veterinarios.map(
                  (vet) {
                    final nombre =
                        vet['nombre']
                                ?.toString() ??
                            '';

                    final especialidad =
                        vet['especialidad']
                                ?.toString() ??
                            '';

                    return DropdownMenuItem<
                        String>(
                      value:
                          vet['id']
                              ?.toString(),

                      child: Text(
                        especialidad
                                .isEmpty
                            ? nombre
                            : '$nombre · $especialidad',

                        maxLines: 1,

                        softWrap: false,

                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                    );
                  },
                ),

                const DropdownMenuItem<
                    String>(
                  value:
                      _opcionAgregarVeterinario,

                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .person_add_alt_1,
                        color:
                            Colors.teal,
                        size: 20,
                      ),

                      SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Text(
                          'Agregar nuevo veterinario',
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              TextStyle(
                            color:
                                Colors.teal,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              onChanged: (valor) async {
                if (valor ==
                    _opcionAgregarVeterinario) {
                  await _agregarNuevoVeterinario();

                  return;
                }

                setState(() {
                  _veterinarioSeleccionado =
                      valor;
                });
              },
            ),

            const SizedBox(height: 14),

            // ===============================================
            // MOTIVO
            // ===============================================

            TextField(
              controller:
                  _motivoController,

              maxLines: 2,

              textCapitalization:
                  TextCapitalization
                      .sentences,

              decoration:
                  InputDecoration(
                labelText:
                    'Motivo de la cita',

                hintText:
                    'Ej. Vacunación, control, revisión...',

                prefixIcon: Icon(
                  Icons
                      .description_outlined,
                  color:
                      Colors.teal.shade700,
                ),

                filled: true,

                fillColor:
                    Colors.teal.shade50,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ===============================================
            // FECHA
            // ===============================================

            SizedBox(
              width: double.infinity,

              child:
                  OutlinedButton.icon(
                onPressed:
                    _seleccionarFecha,

                icon: Icon(
                  Icons.event,
                  color:
                      Colors.teal.shade700,
                ),

                label: Text(
                  _textoFecha(),

                  style: TextStyle(
                    color:
                        Colors.teal.shade700,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                style:
                    OutlinedButton
                        .styleFrom(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 14,
                  ),

                  side: BorderSide(
                    color:
                        Colors.teal
                            .shade200,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ===============================================
            // HORA
            // ===============================================

            SizedBox(
              width: double.infinity,

              child:
                  OutlinedButton.icon(
                onPressed:
                    _seleccionarHora,

                icon: Icon(
                  Icons.access_time,
                  color:
                      Colors.teal.shade700,
                ),

                label: Text(
                  _horaSeleccionada ==
                          null
                      ? 'Seleccionar hora'
                      : _horaSeleccionada!
                          .format(
                            context,
                          ),

                  style: TextStyle(
                    color:
                        Colors.teal.shade700,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                style:
                    OutlinedButton
                        .styleFrom(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 14,
                  ),

                  side: BorderSide(
                    color:
                        Colors.teal
                            .shade200,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      actionsPadding:
          const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        16,
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },

          child: Text(
            'Cancelar',

            style: TextStyle(
              color:
                  Colors.grey.shade700,
            ),
          ),
        ),

        ElevatedButton.icon(
          onPressed: _guardar,

          icon: Icon(
            _esEdicion
                ? Icons.check
                : Icons.save,
          ),

          label: Text(
            _esEdicion
                ? 'Actualizar'
                : 'Guardar',
          ),

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.teal,

            foregroundColor:
                Colors.white,

            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 18,
              vertical: 12,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// FORMULARIO PARA AGREGAR NUEVO VETERINARIO
// ===========================================================

class _NuevoVeterinarioDialog
    extends StatefulWidget {
  const _NuevoVeterinarioDialog();

  @override
  State<_NuevoVeterinarioDialog>
      createState() =>
          _NuevoVeterinarioDialogState();
}

class _NuevoVeterinarioDialogState
    extends State<_NuevoVeterinarioDialog> {
  final TextEditingController
      _nombreController =
      TextEditingController();

  final TextEditingController
      _especialidadController =
      TextEditingController();

  final TextEditingController
      _telefonoController =
      TextEditingController();

  final TextEditingController
      _clinicaController =
      TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();

    _especialidadController.dispose();

    _telefonoController.dispose();

    _clinicaController.dispose();

    super.dispose();
  }

  // =========================================================
  // GUARDAR NUEVO VETERINARIO
  // =========================================================

  void _guardar() {
    final nombre =
        _nombreController.text.trim();

    final especialidad =
        _especialidadController.text
            .trim();

    final telefono =
        _telefonoController.text.trim();

    final clinica =
        _clinicaController.text.trim();

    if (nombre.isEmpty) {
      _mostrarMensaje(
        'Escribe el nombre del veterinario.',
      );

      return;
    }

    if (especialidad.isEmpty) {
      _mostrarMensaje(
        'Escribe la especialidad.',
      );

      return;
    }

    if (telefono.isEmpty) {
      _mostrarMensaje(
        'Escribe el teléfono.',
      );

      return;
    }

    if (clinica.isEmpty) {
      _mostrarMensaje(
        'Escribe la clínica o veterinaria.',
      );

      return;
    }

    Navigator.of(context).pop(
      {
        'nombre': nombre,
        'especialidad':
            especialidad,
        'telefono': telefono,
        'clinica': clinica,
      },
    );
  }

  void _mostrarMensaje(
    String mensaje,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
            Colors.orange.shade700,
        content: Text(mensaje),
      ),
    );
  }

  // =========================================================
  // DECORACIÓN DE CAMPOS
  // =========================================================

  InputDecoration _decoracion({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,

      hintText: hint,

      prefixIcon: Icon(
        icon,
        color: Colors.teal.shade700,
      ),

      filled: true,

      fillColor: Colors.teal.shade50,

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color:
              Colors.teal.shade600,
          width: 1.5,
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,

      surfaceTintColor:
          Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(22),
      ),

      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration:
                BoxDecoration(
              color:
                  Colors.teal.shade50,
              shape: BoxShape.circle,
            ),

            child: Icon(
              Icons.person_add_alt_1,
              color:
                  Colors.teal.shade700,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Nuevo veterinario',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      content:
          SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Text(
              'Registra los datos del veterinario. '
              'Después quedará seleccionado automáticamente.',

              style: TextStyle(
                color:
                    Colors.grey.shade700,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller:
                  _nombreController,

              textCapitalization:
                  TextCapitalization
                      .words,

              decoration:
                  _decoracion(
                label:
                    'Nombre del veterinario',
                hint:
                    'Ej. Dra. Ana Torres',
                icon:
                    Icons.person_outline,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  _especialidadController,

              textCapitalization:
                  TextCapitalization
                      .sentences,

              decoration:
                  _decoracion(
                label: 'Especialidad',
                hint:
                    'Ej. Medicina veterinaria',
                icon:
                    Icons.school_outlined,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  _telefonoController,

              keyboardType:
                  TextInputType.phone,

              decoration:
                  _decoracion(
                label: 'Teléfono',
                hint:
                    'Ej. 099 123 4567',
                icon:
                    Icons.phone_outlined,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  _clinicaController,

              textCapitalization:
                  TextCapitalization
                      .words,

              decoration:
                  _decoracion(
                label:
                    'Clínica o veterinaria',
                hint:
                    'Ej. Clínica Animal Care',
                icon:
                    Icons
                        .local_hospital_outlined,
              ),
            ),
          ],
        ),
      ),

      actionsPadding:
          const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        16,
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },

          child: Text(
            'Cancelar',

            style: TextStyle(
              color:
                  Colors.grey.shade700,
            ),
          ),
        ),

        ElevatedButton.icon(
          onPressed: _guardar,

          icon:
              const Icon(Icons.save),

          label:
              const Text('Guardar'),

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.teal,

            foregroundColor:
                Colors.white,

            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 18,
              vertical: 12,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../services/database_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() =>
      _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final DatabaseService _databaseService =
      DatabaseService.instance;

  List<Map<String, dynamic>> _citas = [];
  List<Pet> _mascotas = [];

  bool _cargando = true;
  bool _cargandoMascotas = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarCitas(),
      _cargarMascotas(),
    ]);
  }

  Future<void> _cargarCitas() async {
    try {
      final citas =
          await _databaseService.obtenerCitasVeterinarias();

      if (!mounted) return;

      setState(() {
        _citas = citas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar las citas: $e',
          ),
        ),
      );
    }
  }

  Future<void> _cargarMascotas() async {
    try {
      final mascotas =
          await _databaseService.obtenerMascotas();

      if (!mounted) return;

      setState(() {
        _mascotas = mascotas
            .where((mascota) => !mascota.deleted)
            .toList();

        _cargandoMascotas = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoMascotas = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar las mascotas: $e',
          ),
        ),
      );
    }
  }

  Future<void> _mostrarFormularioCita() async {
    if (_cargandoMascotas) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Espera un momento mientras se cargan tus mascotas.',
          ),
        ),
      );
      return;
    }

    if (_mascotas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero debes registrar al menos una mascota.',
          ),
        ),
      );
      return;
    }

    final resultado =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return _FormularioCitaDialog(
          mascotas: _mascotas,
        );
      },
    );

    if (resultado == null) return;

    try {
      await _databaseService.insertarCitaVeterinaria(
        mascota: resultado['mascota'] as String,
        veterinario:
            resultado['veterinario'] as String,
        motivo: resultado['motivo'] as String,
        fecha: resultado['fecha'] as String,
        hora: resultado['hora'] as String,
      );

      await _cargarCitas();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cita veterinaria guardada correctamente.',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la cita: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarCita(
    Map<String, dynamic> cita,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Eliminar cita',
          ),
          content: Text(
            '¿Deseas eliminar la cita de '
            '${cita['mascota']}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _databaseService.eliminarCitaVeterinaria(
        cita['id'] as String,
      );

      await _cargarCitas();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cita eliminada correctamente.',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar la cita: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _crearTarjetaCita(
    Map<String, dynamic> cita,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cita['motivo'] as String,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _eliminarCita(cita),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _datoCita(
              Icons.pets,
              'Mascota',
              cita['mascota'] as String,
            ),
            _datoCita(
              Icons.medical_services_outlined,
              'Veterinario',
              cita['veterinario'] as String,
            ),
            _datoCita(
              Icons.calendar_today,
              'Fecha',
              cita['fecha'] as String,
            ),
            _datoCita(
              Icons.access_time,
              'Hora',
              cita['hora'] as String,
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoCita(
    IconData icono,
    String titulo,
    String valor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        children: [
          Icon(
            icono,
            size: 20,
            color: Colors.teal.shade700,
          ),
          const SizedBox(width: 10),
          Text(
            '$titulo: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              valor,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Citas veterinarias',
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
              onRefresh: _cargarDatos,
              child: _citas.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context)
                                      .size
                                      .height *
                                  0.25,
                        ),
                        const Icon(
                          Icons.event_note,
                          size: 80,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'No tienes citas registradas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Padding(
                            padding:
                                EdgeInsets.symmetric(
                              horizontal: 30,
                            ),
                            child: Text(
                              'Agrega una cita veterinaria '
                              'para llevar el control de '
                              'la salud de tu mascota.',
                              textAlign:
                                  TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.all(16),
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
        ),
      ),
    );
  }
}

// ============================================================
// FORMULARIO DE NUEVA CITA
// ============================================================

class _FormularioCitaDialog extends StatefulWidget {
  final List<Pet> mascotas;

  const _FormularioCitaDialog({
    required this.mascotas,
  });

  @override
  State<_FormularioCitaDialog> createState() =>
      _FormularioCitaDialogState();
}

class _FormularioCitaDialogState
    extends State<_FormularioCitaDialog> {
  final TextEditingController _motivoController =
      TextEditingController();

  String? _mascotaSeleccionadaId;
  String? _veterinarioSeleccionado;
  String? _fechaSeleccionada;
  String? _horaSeleccionada;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(
        DateTime.now().year + 5,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha == null) return;

    setState(() {
      _fechaSeleccionada =
          '${fecha.day.toString().padLeft(2, '0')}/'
          '${fecha.month.toString().padLeft(2, '0')}/'
          '${fecha.year}';
    });
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (hora == null) return;

    setState(() {
      _horaSeleccionada = hora.format(context);
    });
  }

  void _guardar() {
    if (_mascotaSeleccionadaId == null) {
      _mostrarMensaje(
        'Selecciona una mascota.',
      );
      return;
    }

    if (_veterinarioSeleccionado == null) {
      _mostrarMensaje(
        'Selecciona un veterinario.',
      );
      return;
    }

    if (_motivoController.text.trim().isEmpty) {
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
          pet.id == _mascotaSeleccionadaId,
    );

    Navigator.of(context).pop({
      'mascota': mascota.nombre,
      'veterinario':
          _veterinarioSeleccionado,
      'motivo':
          _motivoController.text.trim(),
      'fecha': _fechaSeleccionada,
      'hora': _horaSeleccionada,
    });
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.orange.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mascotaSeleccionada =
        _mascotaSeleccionadaId == null
            ? null
            : widget.mascotas.firstWhere(
                (pet) =>
                    pet.id ==
                    _mascotaSeleccionadaId,
              );

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.event_available,
            color: Colors.teal,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nueva cita veterinaria',
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --------------------------------------------------
            // MASCOTA
            // --------------------------------------------------
            DropdownButtonFormField<String>(
              initialValue:
                  _mascotaSeleccionadaId,
              decoration: InputDecoration(
                labelText: 'Mascota',
                hintText:
                    'Selecciona una mascota',
                prefixIcon: const Icon(
                  Icons.pets,
                  color: Colors.teal,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(
                    color: Colors.teal,
                    width: 2,
                  ),
                ),
              ),
              items: widget.mascotas.map(
                (mascota) {
                  return DropdownMenuItem<String>(
                    value: mascota.id,
                    child: Text(
                      '${mascota.nombre} · '
                      '${mascota.especie}',
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  );
                },
              ).toList(),
              onChanged: (value) {
                setState(() {
                  _mascotaSeleccionadaId =
                      value;
                });
              },
            ),

            // --------------------------------------------------
            // INFORMACIÓN DE LA MASCOTA
            // --------------------------------------------------
            if (mascotaSeleccionada != null)
              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.only(
                  top: 10,
                ),
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color:
                          Colors.teal.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${mascotaSeleccionada.nombre} · '
                        '${mascotaSeleccionada.raza} · '
                        '${mascotaSeleccionada.edad} años',
                        style: TextStyle(
                          color:
                              Colors.teal.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // VETERINARIO
            // --------------------------------------------------
            DropdownButtonFormField<String>(
              initialValue:
                  _veterinarioSeleccionado,
              decoration: InputDecoration(
                labelText: 'Veterinario',
                hintText:
                    'Selecciona un veterinario',
                prefixIcon: const Icon(
                  Icons.medical_services,
                  color: Colors.teal,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(
                    color: Colors.teal,
                    width: 2,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem<String>(
                  value:
                      'Dr. Carlos Mendoza',
                  child: Text(
                    'Dr. Carlos Mendoza',
                  ),
                ),
                DropdownMenuItem<String>(
                  value:
                      'Dra. Ana Torres',
                  child: Text(
                    'Dra. Ana Torres',
                  ),
                ),
                DropdownMenuItem<String>(
                  value:
                      'Dr. Miguel Rodríguez',
                  child: Text(
                    'Dr. Miguel Rodríguez',
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _veterinarioSeleccionado =
                      value;
                });
              },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // MOTIVO
            // --------------------------------------------------
            TextField(
              controller:
                  _motivoController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Motivo de la cita',
                hintText:
                    'Ej. Vacunación, revisión, control...',
                prefixIcon: const Icon(
                  Icons.description_outlined,
                  color: Colors.teal,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(
                    color: Colors.teal,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // FECHA
            // --------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _seleccionarFecha,
                icon: const Icon(
                  Icons.calendar_today,
                  color: Colors.teal,
                ),
                label: Text(
                  _fechaSeleccionada ??
                      'Seleccionar fecha',
                  style: const TextStyle(
                    color: Colors.teal,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------
            // HORA
            // --------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _seleccionarHora,
                icon: const Icon(
                  Icons.access_time,
                  color: Colors.teal,
                ),
                label: Text(
                  _horaSeleccionada ??
                      'Seleccionar hora',
                  style: const TextStyle(
                    color: Colors.teal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _guardar,
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
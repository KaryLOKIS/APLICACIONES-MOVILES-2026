import 'package:flutter/material.dart';

import '../services/database_service.dart';

class DewormingScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const DewormingScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<DewormingScreen> createState() =>
      _DewormingScreenState();
}

class _DewormingScreenState
    extends State<DewormingScreen> {
  final DatabaseService _databaseService =
      DatabaseService.instance;

  List<Map<String, dynamic>> _desparasitaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDesparasitaciones();
  }

  // =========================================================
  // CARGAR DESPARASITACIONES
  // =========================================================

  Future<void> _cargarDesparasitaciones() async {
    setState(() {
      _cargando = true;
    });

    try {
      final resultados =
          await _databaseService
              .obtenerDesparasitacionesPorMascota(
        widget.petId,
      );

      if (!mounted) return;

      setState(() {
        _desparasitaciones = resultados;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron cargar las desparasitaciones.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // MOSTRAR FORMULARIO
  // =========================================================

  Future<void> _mostrarFormulario({
    Map<String, dynamic>? desparasitacion,
  }) async {
    final resultado =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return _FormularioDesparasitacionDialog(
          desparasitacion: desparasitacion,
        );
      },
    );

    if (resultado == null) {
      return;
    }

    try {
      if (desparasitacion == null) {
        await _databaseService.insertarDesparasitacion(
          petId: widget.petId,
          tipo: resultado['tipo'] as String,
          fechaAplicacion:
              resultado['fecha_aplicacion'] as String,
          proximaDosis:
              resultado['proxima_dosis'] as String?,
          veterinario:
              resultado['veterinario'] as String,
          observaciones:
              resultado['observaciones'] as String,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Desparasitación registrada correctamente.',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        await _databaseService.actualizarDesparasitacion(
          id: desparasitacion['id'] as String,
          petId: widget.petId,
          tipo: resultado['tipo'] as String,
          fechaAplicacion:
              resultado['fecha_aplicacion'] as String,
          proximaDosis:
              resultado['proxima_dosis'] as String?,
          veterinario:
              resultado['veterinario'] as String,
          observaciones:
              resultado['observaciones'] as String,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Desparasitación actualizada correctamente.',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }

      await _cargarDesparasitaciones();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar la desparasitación.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // ELIMINAR
  // =========================================================

  Future<void> _eliminarDesparasitacion(
    Map<String, dynamic> desparasitacion,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Eliminar desparasitación',
          ),
          content: const Text(
            '¿Deseas eliminar este registro de desparasitación?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
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
      await _databaseService.eliminarDesparasitacion(
        desparasitacion['id'] as String,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Desparasitación eliminada correctamente.',
          ),
          backgroundColor: Colors.teal,
        ),
      );

      await _cargarDesparasitaciones();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo eliminar la desparasitación.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // FORMATO DE FECHA
  // =========================================================

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);

      final dia =
          dateTime.day.toString().padLeft(2, '0');

      final mes =
          dateTime.month.toString().padLeft(2, '0');

      final anio = dateTime.year;

      return '$dia/$mes/$anio';
    } catch (_) {
      return fecha;
    }
  }

  bool _estaVencida(String? fecha) {
    if (fecha == null || fecha.isEmpty) {
      return false;
    }

    try {
      final fechaProxima = DateTime.parse(fecha);

      final hoy = DateTime.now();

      final fechaSoloDia = DateTime(
        fechaProxima.year,
        fechaProxima.month,
        fechaProxima.day,
      );

      final hoySoloDia = DateTime(
        hoy.year,
        hoy.month,
        hoy.day,
      );

      return fechaSoloDia.isBefore(hoySoloDia);
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(
          'Desparasitación de ${widget.petName}',
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.teal,
              ),
            )
          : RefreshIndicator(
              color: Colors.teal,
              onRefresh: _cargarDesparasitaciones,
              child: _desparasitaciones.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 80),
                        Icon(
                          Icons.medical_services_outlined,
                          size: 80,
                          color: Colors.teal.shade300,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No hay desparasitaciones registradas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Registra las desparasitaciones de '
                          '${widget.petName} para llevar un mejor '
                          'control de su salud.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.teal,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                          onPressed:
                              _mostrarFormulario,
                          icon: const Icon(
                            Icons.add,
                          ),
                          label: const Text(
                            'Registrar desparasitación',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          _desparasitaciones.length,
                      itemBuilder:
                          (context, index) {
                        final registro =
                            _desparasitaciones[index];

                        final proximaDosis =
                            registro[
                                    'proxima_dosis']
                                as String?;

                        final vencida =
                            _estaVencida(
                          proximaDosis,
                        );

                        return Card(
                          margin:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          elevation: 2,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration:
                                          BoxDecoration(
                                        color: Colors
                                            .teal
                                            .shade50,
                                        shape:
                                            BoxShape
                                                .circle,
                                      ),
                                      child: Icon(
                                        Icons
                                            .medical_services,
                                        color: Colors
                                            .teal
                                            .shade700,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 14,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            registro[
                                                    'tipo']
                                                as String,
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  18,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            'Aplicación: '
                                            '${_formatearFecha(
                                              registro[
                                                      'fecha_aplicacion']
                                                  as String,
                                            )}',
                                            style:
                                                TextStyle(
                                              color: Colors
                                                  .grey
                                                  .shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected:
                                          (opcion) {
                                        if (opcion ==
                                            'editar') {
                                          _mostrarFormulario(
                                            desparasitacion:
                                                registro,
                                          );
                                        } else if (opcion ==
                                            'eliminar') {
                                          _eliminarDesparasitacion(
                                            registro,
                                          );
                                        }
                                      },
                                      itemBuilder:
                                          (context) =>
                                              const [
                                        PopupMenuItem(
                                          value:
                                              'editar',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                              ),
                                              SizedBox(
                                                width:
                                                    8,
                                              ),
                                              Text(
                                                'Editar',
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value:
                                              'eliminar',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .delete,
                                                color: Colors
                                                    .red,
                                              ),
                                              SizedBox(
                                                width:
                                                    8,
                                              ),
                                              Text(
                                                'Eliminar',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 16,
                                ),

                                const Divider(),

                                const SizedBox(
                                  height: 10,
                                ),

                                _dato(
                                  icono:
                                      Icons.person,
                                  titulo:
                                      'Veterinario',
                                  valor:
                                      registro[
                                              'veterinario']
                                          as String,
                                ),

                                const SizedBox(
                                  height: 10,
                                ),

                                _dato(
                                  icono:
                                      Icons.event,
                                  titulo:
                                      'Próxima dosis',
                                  valor:
                                      proximaDosis !=
                                                  null &&
                                              proximaDosis
                                                  .isNotEmpty
                                          ? _formatearFecha(
                                              proximaDosis,
                                            )
                                          : 'No registrada',
                                  color: vencida
                                      ? Colors.red
                                      : Colors.teal
                                          .shade700,
                                ),

                                const SizedBox(
                                  height: 10,
                                ),

                                _dato(
                                  icono:
                                      Icons.notes,
                                  titulo:
                                      'Observaciones',
                                  valor:
                                      (registro[
                                                  'observaciones']
                                              as String)
                                          .isNotEmpty
                                      ? registro[
                                              'observaciones']
                                          as String
                                      : 'Sin observaciones',
                                ),

                                if (vencida) ...[
                                  const SizedBox(
                                    height: 14,
                                  ),
                                  Container(
                                    width:
                                        double.infinity,
                                    padding:
                                        const EdgeInsets
                                            .all(12),
                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .red
                                          .shade50,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        12,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .warning_amber,
                                          color: Colors
                                              .red
                                              .shade700,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: Text(
                                            'La próxima '
                                            'desparasitación '
                                            'ya está vencida.',
                                            style:
                                                TextStyle(
                                              color: Colors
                                                  .red
                                                  .shade700,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.add),
        label: const Text(
          'Desparasitar',
        ),
      ),
    );
  }

  // =========================================================
  // DATO
  // =========================================================

  Widget _dato({
    required IconData icono,
    required String titulo,
    required String valor,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          size: 20,
          color: color ?? Colors.teal.shade700,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
              children: [
                TextSpan(
                  text: '$titulo: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: valor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// FORMULARIO DE DESPARASITACIÓN
// ===========================================================

class _FormularioDesparasitacionDialog
    extends StatefulWidget {
  final Map<String, dynamic>? desparasitacion;

  const _FormularioDesparasitacionDialog({
    this.desparasitacion,
  });

  @override
  State<_FormularioDesparasitacionDialog>
      createState() =>
          _FormularioDesparasitacionDialogState();
}

class _FormularioDesparasitacionDialogState
    extends State<_FormularioDesparasitacionDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tipoController;
  late final TextEditingController
      _observacionesController;

  final DatabaseService _databaseService =
      DatabaseService.instance;

  List<Map<String, dynamic>> _veterinarios = [];

  String? _veterinarioSeleccionado;
  DateTime? _fechaAplicacion;
  DateTime? _proximaDosis;

  @override
  void initState() {
    super.initState();

    final registro = widget.desparasitacion;

    _tipoController = TextEditingController(
      text: registro?['tipo'] as String? ?? '',
    );

    _observacionesController =
        TextEditingController(
      text:
          registro?['observaciones'] as String? ?? '',
    );

    _veterinarioSeleccionado =
        registro?['veterinario'] as String?;

    final fechaAplicacion =
        registro?['fecha_aplicacion'] as String?;

    final proximaDosis =
        registro?['proxima_dosis'] as String?;

    if (fechaAplicacion != null &&
        fechaAplicacion.isNotEmpty) {
      _fechaAplicacion =
          DateTime.tryParse(fechaAplicacion);
    }

    if (proximaDosis != null &&
        proximaDosis.isNotEmpty) {
      _proximaDosis =
          DateTime.tryParse(proximaDosis);
    }

    _cargarVeterinarios();
  }

  @override
  void dispose() {
    _tipoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  // =========================================================
  // CARGAR VETERINARIOS
  // =========================================================

  Future<void> _cargarVeterinarios() async {
    final veterinarios =
        await _databaseService
            .obtenerVeterinarios();

    if (!mounted) return;

    setState(() {
      _veterinarios = veterinarios;
    });
  }

  // =========================================================
  // FECHA
  // =========================================================

  Future<void> _seleccionarFechaAplicacion() async {
    final seleccionada =
        await showDatePicker(
      context: context,
      initialDate:
          _fechaAplicacion ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText:
          'Selecciona la fecha de aplicación',
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
    );

    if (seleccionada == null) {
      return;
    }

    setState(() {
      _fechaAplicacion = seleccionada;
    });

    if (_proximaDosis != null &&
        _proximaDosis!
            .isBefore(seleccionada)) {
      setState(() {
        _proximaDosis = null;
      });
    }
  }

  Future<void> _seleccionarProximaDosis() async {
    final fechaBase =
        _fechaAplicacion ?? DateTime.now();

    final seleccionada =
        await showDatePicker(
      context: context,
      initialDate:
          _proximaDosis ??
              fechaBase.add(
                const Duration(days: 30),
              ),
      firstDate: fechaBase,
      lastDate: DateTime(2100),
      helpText:
          'Selecciona la próxima dosis',
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
    );

    if (seleccionada == null) {
      return;
    }

    setState(() {
      _proximaDosis = seleccionada;
    });
  }

  // =========================================================
  // FORMATO
  // =========================================================

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'Seleccionar fecha';
    }

    final dia =
        fecha.day.toString().padLeft(2, '0');

    final mes =
        fecha.month.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year}';
  }

  // =========================================================
  // GUARDAR
  // =========================================================

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaAplicacion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona la fecha de aplicación.',
          ),
        ),
      );
      return;
    }

    if (_veterinarioSeleccionado == null ||
        _veterinarioSeleccionado!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona un veterinario.',
          ),
        ),
      );
      return;
    }

    if (_proximaDosis != null &&
        _proximaDosis!
            .isBefore(_fechaAplicacion!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La próxima dosis no puede ser anterior '
            'a la fecha de aplicación.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'tipo': _tipoController.text.trim(),
      'fecha_aplicacion':
          _fechaAplicacion!.toIso8601String(),
      'proxima_dosis':
          _proximaDosis?.toIso8601String(),
      'veterinario':
          _veterinarioSeleccionado!,
      'observaciones':
          _observacionesController.text.trim(),
    });
  }

  // =========================================================
  // BUILD FORMULARIO
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final esEdicion =
        widget.desparasitacion != null;

    return AlertDialog(
      title: Text(
        esEdicion
            ? 'Editar desparasitación'
            : 'Registrar desparasitación',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tipoController,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText:
                      'Producto o medicamento',
                  hintText:
                      'Ej.: Drontal, NexGard, etc.',
                  prefixIcon: const Icon(
                    Icons.medication,
                  ),
                  filled: true,
                  fillColor: Colors.teal.shade50,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Ingresa el producto utilizado.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue:
                    _veterinarioSeleccionado,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Veterinario',
                  prefixIcon: const Icon(
                    Icons.person,
                  ),
                  filled: true,
                  fillColor: Colors.teal.shade50,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _veterinarios.map(
                  (veterinario) {
                    final nombre =
                        veterinario['nombre']
                            as String;

                    final especialidad =
                        veterinario[
                                'especialidad']
                            as String;

                    return DropdownMenuItem<
                        String>(
                      value: nombre,
                      child: Text(
                        '$nombre · $especialidad',
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    _veterinarioSeleccionado =
                        value;
                  });
                },
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Selecciona un veterinario.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(
                      color: Colors.teal,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      _seleccionarFechaAplicacion,
                  icon: const Icon(
                    Icons.calendar_today,
                  ),
                  label: Text(
                    'Aplicación: '
                    '${_formatearFecha(
                      _fechaAplicacion,
                    )}',
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(
                      color: Colors.teal,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      _seleccionarProximaDosis,
                  icon: const Icon(
                    Icons.event_available,
                  ),
                  label: Text(
                    'Próxima dosis: '
                    '${_formatearFecha(
                      _proximaDosis,
                    )}',
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller:
                    _observacionesController,
                maxLines: 3,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Observaciones',
                  hintText:
                      'Información adicional...',
                  prefixIcon: const Icon(
                    Icons.notes,
                  ),
                  filled: true,
                  fillColor: Colors.teal.shade50,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancelar',
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          onPressed: _guardar,
          child: Text(
            esEdicion ? 'Guardar cambios' : 'Guardar',
          ),
        ),
      ],
    );
  }
}
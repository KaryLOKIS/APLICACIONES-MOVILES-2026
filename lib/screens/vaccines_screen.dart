import 'package:flutter/material.dart';

import '../services/database_service.dart';

class VaccinesScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const VaccinesScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<VaccinesScreen> createState() => _VaccinesScreenState();
}

class _VaccinesScreenState extends State<VaccinesScreen> {
  final DatabaseService _databaseService =
      DatabaseService.instance;

  List<Map<String, dynamic>> _vacunas = [];
  List<Map<String, dynamic>> _veterinarios = [];

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final vacunas = await _databaseService
          .obtenerVacunasPorMascota(widget.petId);

      final veterinarios =
          await _databaseService.obtenerVeterinarios();

      if (!mounted) return;

      setState(() {
        _vacunas = vacunas
            .map(
              (vacuna) =>
                  Map<String, dynamic>.from(vacuna),
            )
            .toList();

        _veterinarios = veterinarios
            .map(
              (veterinario) =>
                  Map<String, dynamic>.from(veterinario),
            )
            .toList();

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
            'No se pudieron cargar las vacunas: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _abrirFormulario({
    Map<String, dynamic>? vacuna,
  }) async {
    final resultado =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) {
        return _FormularioVacunaDialog(
          vacuna: vacuna,
          veterinarios: _veterinarios,
        );
      },
    );

    if (resultado == null) return;

    try {
      if (vacuna == null) {
        await _databaseService.insertarVacuna(
          petId: widget.petId,
          vacuna: resultado['vacuna'] as String,
          fechaAplicacion:
              resultado['fecha_aplicacion'] as String,
          proximaDosis:
              resultado['proxima_dosis'] as String? ?? '',
          veterinario:
              resultado['veterinario'] as String? ?? '',
          observaciones:
              resultado['observaciones'] as String? ?? '',
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vacuna registrada correctamente.',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        await _databaseService.actualizarVacuna(
          id: vacuna['id'] as String,
          petId: widget.petId,
          vacuna: resultado['vacuna'] as String,
          fechaAplicacion:
              resultado['fecha_aplicacion'] as String,
          proximaDosis:
              resultado['proxima_dosis'] as String? ?? '',
          veterinario:
              resultado['veterinario'] as String? ?? '',
          observaciones:
              resultado['observaciones'] as String? ?? '',
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vacuna actualizada correctamente.',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }

      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la vacuna: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarVacuna(
    Map<String, dynamic> vacuna,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Eliminar vacuna',
          ),
          content: Text(
            '¿Deseas eliminar el registro de '
            '"${vacuna['vacuna']}"?',
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

    if (confirmar != true) return;

    try {
      await _databaseService.eliminarVacuna(
        vacuna['id'] as String,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vacuna eliminada correctamente.',
          ),
          backgroundColor: Colors.teal,
        ),
      );

      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar la vacuna: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) {
      return 'No registrada';
    }

    try {
      final date = DateTime.parse(fecha);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return fecha;
    }
  }

  bool _fechaVencida(String? fecha) {
    if (fecha == null || fecha.isEmpty) {
      return false;
    }

    try {
      final fechaDosis = DateTime.parse(fecha);
      final hoy = DateTime.now();

      return fechaDosis.isBefore(
        DateTime(
          hoy.year,
          hoy.month,
          hoy.day,
        ),
      );
    } catch (_) {
      return false;
    }
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
          'Vacunas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Registrar vacuna',
        ),
        onPressed: () {
          _abrirFormulario();
        },
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
              child: _vacunas.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 70),
                        Icon(
                          Icons.vaccines_outlined,
                          size: 90,
                          color: Colors.teal.shade300,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No hay vacunas registradas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Registra las vacunas de '
                          '${widget.petName} para llevar '
                          'su historial de salud.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 14,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              _abrirFormulario();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text(
                              'Registrar primera vacuna',
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        100,
                      ),
                      itemCount: _vacunas.length,
                      itemBuilder: (context, index) {
                        final vacuna = _vacunas[index];

                        final nombreVacuna =
                            vacuna['vacuna']?.toString() ??
                                'Vacuna';

                        final veterinario =
                            vacuna['veterinario']
                                    ?.toString() ??
                                'No registrado';

                        final observaciones =
                            vacuna['observaciones']
                                    ?.toString() ??
                                '';

                        final proximaDosis =
                            vacuna['proxima_dosis']
                                    ?.toString();

                        final vencida =
                            _fechaVencida(proximaDosis);

                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset:
                                    const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.all(
                                        11,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color: Colors.teal
                                            .shade50,
                                        borderRadius:
                                            BorderRadius
                                                .circular(14),
                                      ),
                                      child: Icon(
                                        Icons.vaccines,
                                        color: Colors.teal
                                            .shade700,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            nombreVacuna,
                                            style:
                                                const TextStyle(
                                              fontSize: 18,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          Text(
                                            widget.petName,
                                            style: TextStyle(
                                              color: Colors
                                                  .grey
                                                  .shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'editar') {
                                          _abrirFormulario(
                                            vacuna: vacuna,
                                          );
                                        } else if (value ==
                                            'eliminar') {
                                          _eliminarVacuna(
                                            vacuna,
                                          );
                                        }
                                      },
                                      itemBuilder: (context) {
                                        return const [
                                          PopupMenuItem(
                                            value: 'editar',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  size: 20,
                                                ),
                                                SizedBox(
                                                  width: 8,
                                                ),
                                                Text('Editar'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'eliminar',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  size: 20,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(
                                                  width: 8,
                                                ),
                                                Text(
                                                  'Eliminar',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ];
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _datoVacuna(
                                  icono:
                                      Icons.calendar_today,
                                  titulo:
                                      'Fecha de aplicación',
                                  valor: _formatearFecha(
                                    vacuna[
                                        'fecha_aplicacion'],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _datoVacuna(
                                  icono:
                                      Icons.event_available,
                                  titulo:
                                      'Próxima dosis',
                                  valor: _formatearFecha(
                                    proximaDosis,
                                  ),
                                  color: vencida
                                      ? Colors.red
                                      : Colors.teal.shade700,
                                ),
                                const SizedBox(height: 10),
                                _datoVacuna(
                                  icono:
                                      Icons.medical_services,
                                  titulo: 'Veterinario',
                                  valor: veterinario,
                                ),
                                if (observaciones.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _datoVacuna(
                                    icono: Icons.notes,
                                    titulo: 'Observaciones',
                                    valor: observaciones,
                                  ),
                                ],
                                if (vencida) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding:
                                        const EdgeInsets.all(
                                      10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red
                                          .shade50,
                                      borderRadius:
                                          BorderRadius.circular(
                                        10,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber,
                                          color:
                                              Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'La próxima dosis '
                                            'ya está pendiente.',
                                            style: TextStyle(
                                              color: Colors
                                                  .red
                                                  .shade700,
                                              fontWeight:
                                                  FontWeight.w600,
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
    );
  }

  Widget _datoVacuna({
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
          color: color ?? Colors.teal.shade600,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      color ?? Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormularioVacunaDialog extends StatefulWidget {
  final Map<String, dynamic>? vacuna;
  final List<Map<String, dynamic>> veterinarios;

  const _FormularioVacunaDialog({
    required this.vacuna,
    required this.veterinarios,
  });

  @override
  State<_FormularioVacunaDialog> createState() =>
      _FormularioVacunaDialogState();
}

class _FormularioVacunaDialogState
    extends State<_FormularioVacunaDialog> {
  final TextEditingController _vacunaController =
      TextEditingController();

  final TextEditingController _observacionesController =
      TextEditingController();

  String? _veterinarioSeleccionado;

  DateTime? _fechaAplicacion;
  DateTime? _proximaDosis;

  @override
  void initState() {
    super.initState();

    final vacuna = widget.vacuna;

    if (vacuna != null) {
      _vacunaController.text =
          vacuna['vacuna']?.toString() ?? '';

      _observacionesController.text =
          vacuna['observaciones']?.toString() ?? '';

      final veterinario =
          vacuna['veterinario']?.toString();

      if (veterinario != null &&
          veterinario.isNotEmpty) {
        final existe = widget.veterinarios.any(
          (item) =>
              item['nombre']?.toString() ==
              veterinario,
        );

        if (existe) {
          _veterinarioSeleccionado =
              veterinario;
        }
      }

      final fechaAplicacion =
          vacuna['fecha_aplicacion']?.toString();

      if (fechaAplicacion != null &&
          fechaAplicacion.isNotEmpty) {
        try {
          _fechaAplicacion =
              DateTime.parse(fechaAplicacion);
        } catch (_) {}
      }

      final proximaDosis =
          vacuna['proxima_dosis']?.toString();

      if (proximaDosis != null &&
          proximaDosis.isNotEmpty) {
        try {
          _proximaDosis =
              DateTime.parse(proximaDosis);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _vacunaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaAplicacion() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate:
          _fechaAplicacion ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Fecha de aplicación',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (fecha == null) return;

    setState(() {
      _fechaAplicacion = fecha;
    });
  }

  Future<void> _seleccionarProximaDosis() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate:
          _proximaDosis ??
          _fechaAplicacion ??
          DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Próxima dosis',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (fecha == null) return;

    setState(() {
      _proximaDosis = fecha;
    });
  }

  String _mostrarFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'Seleccionar fecha';
    }

    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  void _guardar() {
    final nombreVacuna =
        _vacunaController.text.trim();

    if (nombreVacuna.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa el nombre de la vacuna.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_fechaAplicacion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona la fecha de aplicación.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_proximaDosis != null &&
        _proximaDosis!.isBefore(_fechaAplicacion!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La próxima dosis no puede ser anterior '
            'a la fecha de aplicación.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'vacuna': nombreVacuna,
      'fecha_aplicacion':
          _fechaAplicacion!.toIso8601String(),
      'proxima_dosis':
          _proximaDosis?.toIso8601String() ?? '',
      'veterinario':
          _veterinarioSeleccionado ?? '',
      'observaciones':
          _observacionesController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.vaccines,
            color: Colors.teal.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.vacuna == null
                  ? 'Registrar vacuna'
                  : 'Editar vacuna',
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Completa la información de la vacuna.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _vacunaController,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre de la vacuna',
                hintText:
                    'Ej.: Rabia, Séxtuple, Triple felina',
                prefixIcon: const Icon(
                  Icons.vaccines,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(
                    color: Colors.teal,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue:
                  _veterinarioSeleccionado,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Veterinario',
                prefixIcon: const Icon(
                  Icons.medical_services,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(
                    color: Colors.teal,
                    width: 2,
                  ),
                ),
              ),
              hint: const Text(
                'Seleccionar veterinario',
              ),
              items: widget.veterinarios.map(
                (veterinario) {
                  final nombre =
                      veterinario['nombre']
                              ?.toString() ??
                          '';

                  final especialidad =
                      veterinario['especialidad']
                              ?.toString() ??
                          '';

                  return DropdownMenuItem<String>(
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
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal.shade700,
                  side: BorderSide(
                    color: Colors.teal.shade300,
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
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Aplicación: '
                    '${_mostrarFecha(_fechaAplicacion)}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal.shade700,
                  side: BorderSide(
                    color: Colors.teal.shade300,
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
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Próxima dosis: '
                    '${_mostrarFecha(_proximaDosis)}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller:
                  _observacionesController,
              textCapitalization:
                  TextCapitalization.sentences,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Observaciones',
                hintText:
                    'Información adicional...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(
                    bottom: 45,
                  ),
                  child: Icon(Icons.notes),
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(
                    color: Colors.teal,
                    width: 2,
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
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          onPressed: _guardar,
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
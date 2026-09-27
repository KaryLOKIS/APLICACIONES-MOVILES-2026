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
  final DatabaseService _databaseService = DatabaseService.instance;

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
      final vacunas =
          await _databaseService.obtenerVacunasPorMascota(widget.petId);

      final veterinarios =
          await _databaseService.obtenerVeterinarios();

      if (!mounted) return;

      setState(() {
        _vacunas = vacunas
            .map((vacuna) => Map<String, dynamic>.from(vacuna))
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
      barrierDismissible: false,
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

          // Se conserva vacío únicamente por compatibilidad
          // con DatabaseService.
          proximaDosis: '',

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

          // Se conserva vacío únicamente por compatibilidad
          // con DatabaseService.
          proximaDosis: '',

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
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Eliminar vacuna',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
                              shape: RoundedRectangleBorder(
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

                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.06,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
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
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.teal.shade50,
                                        borderRadius:
                                            BorderRadius.circular(
                                          14,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.vaccines,
                                        color:
                                            Colors.teal.shade700,
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
                                                  FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.petName,
                                            style: TextStyle(
                                              color: Colors
                                                  .grey.shade600,
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
                                        }

                                        if (value ==
                                            'eliminar') {
                                          _eliminarVacuna(
                                            vacuna,
                                          );
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'editar',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit_outlined,
                                                color: Colors.teal,
                                              ),
                                              SizedBox(width: 10),
                                              Text('Editar'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'eliminar',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .delete_outline,
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

                                const SizedBox(height: 16),

                                Divider(
                                  height: 1,
                                  color: Colors.grey.shade200,
                                ),

                                const SizedBox(height: 14),

                                _datoVacuna(
                                  icono:
                                      Icons.calendar_today_outlined,
                                  titulo: 'Aplicación',
                                  valor: _formatearFecha(
                                    vacuna['fecha_aplicacion']
                                        ?.toString(),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                _datoVacuna(
                                  icono: Icons
                                      .medical_services_outlined,
                                  titulo: 'Veterinario',
                                  valor: veterinario.isEmpty
                                      ? 'No registrado'
                                      : veterinario,
                                ),

                                if (observaciones
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _datoVacuna(
                                    icono: Icons.notes,
                                    titulo: 'Observaciones',
                                    valor: observaciones,
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          size: 20,
          color: Colors.teal.shade600,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// FORMULARIO DE VACUNA
// ===========================================================

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
  final DatabaseService _databaseService =
      DatabaseService.instance;

  static const String _agregarVacuna =
      '__agregar_vacuna__';

  static const String _agregarVeterinario =
      '__agregar_veterinario__';

  final TextEditingController _nuevaVacunaController =
      TextEditingController();

  final TextEditingController _observacionesController =
      TextEditingController();

  List<Map<String, dynamic>> _veterinarios = [];

  final List<String> _catalogoVacunas = const [
    'Rabia',
    'Polivalente',
    'Séxtuple',
    'Quíntuple',
    'Bordetella',
    'Leptospirosis',
    'Triple felina',
    'Leucemia felina',
  ];

  String? _vacunaSeleccionada;
  String? _veterinarioSeleccionado;

  DateTime? _fechaAplicacion;

  bool _mostrarNuevaVacuna = false;
  bool _guardandoVeterinario = false;

  @override
  void initState() {
    super.initState();

    _veterinarios = widget.veterinarios
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();

    final vacuna = widget.vacuna;

    if (vacuna != null) {
      final nombreVacuna =
          vacuna['vacuna']?.toString().trim() ?? '';

      final opcionExistente =
          _buscarOpcionVacuna(nombreVacuna);

      if (opcionExistente != null) {
        _vacunaSeleccionada = opcionExistente;
      } else if (nombreVacuna.isNotEmpty) {
        _vacunaSeleccionada = _agregarVacuna;
        _mostrarNuevaVacuna = true;
        _nuevaVacunaController.text = nombreVacuna;
      }

      _observacionesController.text =
          vacuna['observaciones']?.toString() ?? '';

      final veterinario =
          vacuna['veterinario']?.toString();

      if (veterinario != null &&
          veterinario.isNotEmpty) {
        final existe = _veterinarios.any(
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
        _fechaAplicacion =
            DateTime.tryParse(fechaAplicacion);
      }
    }
  }

  String? _buscarOpcionVacuna(String nombre) {
    final normalizado = nombre.trim().toLowerCase();

    for (final opcion in _catalogoVacunas) {
      if (opcion.toLowerCase() == normalizado) {
        return opcion;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _nuevaVacunaController.dispose();
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

    if (fecha == null || !mounted) return;

    setState(() {
      _fechaAplicacion = fecha;
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

  Future<void> _agregarVeterinarioNuevo() async {
    final resultado =
        await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const _NuevoVeterinarioDialog(),
    );

    if (resultado == null || !mounted) {
      return;
    }

    setState(() {
      _guardandoVeterinario = true;
    });

    try {
      await _databaseService.insertarVeterinario(
        nombre: resultado['nombre']!,
        especialidad: resultado['especialidad']!,
        telefono: resultado['telefono']!,
        clinica: resultado['clinica']!,
      );

      final veterinarios =
          await _databaseService.obtenerVeterinarios();

      if (!mounted) return;

      setState(() {
        _veterinarios = veterinarios
            .map(
              (item) =>
                  Map<String, dynamic>.from(item),
            )
            .toList();

        _veterinarioSeleccionado =
            resultado['nombre'];

        _guardandoVeterinario = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veterinario agregado y seleccionado.',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardandoVeterinario = false;
        _veterinarioSeleccionado = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo agregar el veterinario: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _guardar() {
    String nombreVacuna;

    if (_vacunaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona una vacuna.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_vacunaSeleccionada == _agregarVacuna) {
      nombreVacuna =
          _nuevaVacunaController.text.trim();

      if (nombreVacuna.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Escribe el nombre de la nueva vacuna.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      nombreVacuna = _vacunaSeleccionada!;
    }

    if (_veterinarioSeleccionado == null ||
        _veterinarioSeleccionado!.isEmpty ||
        _veterinarioSeleccionado ==
            _agregarVeterinario) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona un veterinario.',
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

    Navigator.of(context).pop({
      'vacuna': nombreVacuna,
      'fecha_aplicacion':
          _fechaAplicacion!.toIso8601String(),
      'veterinario':
          _veterinarioSeleccionado!,
      'observaciones':
          _observacionesController.text.trim(),
    });
  }

  InputDecoration _decoracionCampo({
    required String label,
    required IconData icono,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icono,
        color: Colors.teal,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.teal,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
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

            // =================================================
            // VACUNA
            // =================================================

            DropdownButtonFormField<String>(
              initialValue: _vacunaSeleccionada,
              isExpanded: true,
              decoration: _decoracionCampo(
                label: 'Vacuna',
                icono: Icons.vaccines,
                hint: 'Seleccionar vacuna',
              ),
              items: [
                ..._catalogoVacunas.map(
                  (vacuna) {
                    return DropdownMenuItem<String>(
                      value: vacuna,
                      child: Text(
                        vacuna,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),

                const DropdownMenuItem<String>(
                  value: _agregarVacuna,
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.teal,
                        size: 21,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Agregar nueva vacuna',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _vacunaSeleccionada = value;

                  if (value == _agregarVacuna) {
                    _mostrarNuevaVacuna = true;
                  } else {
                    _mostrarNuevaVacuna = false;
                    _nuevaVacunaController.clear();
                  }
                });
              },
            ),

            if (_mostrarNuevaVacuna) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _nuevaVacunaController,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: _decoracionCampo(
                  label: 'Nombre de la vacuna',
                  icono: Icons.edit_outlined,
                  hint: 'Escribe el nombre',
                ),
              ),
            ],

            const SizedBox(height: 14),

            // =================================================
            // VETERINARIO
            // =================================================

            DropdownButtonFormField<String>(
              initialValue:
                  _veterinarioSeleccionado,
              isExpanded: true,
              decoration: _decoracionCampo(
                label: 'Veterinario',
                icono: Icons.medical_services,
                hint: 'Seleccionar veterinario',
              ),
              items: [
                ..._veterinarios.map(
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
                        especialidad.isEmpty
                            ? nombre
                            : '$nombre · $especialidad',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),

                const DropdownMenuItem<String>(
                  value: _agregarVeterinario,
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_alt_1,
                        color: Colors.teal,
                        size: 21,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Agregar nuevo veterinario',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: _guardandoVeterinario
                  ? null
                  : (value) async {
                      if (value ==
                          _agregarVeterinario) {
                        await _agregarVeterinarioNuevo();
                        return;
                      }

                      setState(() {
                        _veterinarioSeleccionado =
                            value;
                      });
                    },
            ),

            const SizedBox(height: 14),

            // =================================================
            // FECHA DE APLICACIÓN
            // =================================================

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.teal.shade700,
                  side: BorderSide(
                    color: Colors.teal.shade300,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
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

            const SizedBox(height: 14),

            // =================================================
            // OBSERVACIONES
            // =================================================

            TextField(
              controller:
                  _observacionesController,
              textCapitalization:
                  TextCapitalization.sentences,
              maxLines: 3,
              decoration: _decoracionCampo(
                label: 'Observaciones',
                icono: Icons.notes,
                hint: 'Información adicional...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardandoVeterinario
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          onPressed: _guardandoVeterinario
              ? null
              : _guardar,
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ===========================================================
// NUEVO VETERINARIO
// ===========================================================

class _NuevoVeterinarioDialog
    extends StatefulWidget {
  const _NuevoVeterinarioDialog();

  @override
  State<_NuevoVeterinarioDialog> createState() =>
      _NuevoVeterinarioDialogState();
}

class _NuevoVeterinarioDialogState
    extends State<_NuevoVeterinarioDialog> {
  late final TextEditingController
      _nombreController;

  late final TextEditingController
      _especialidadController;

  late final TextEditingController
      _telefonoController;

  late final TextEditingController
      _clinicaController;

  @override
  void initState() {
    super.initState();

    _nombreController =
        TextEditingController();

    _especialidadController =
        TextEditingController();

    _telefonoController =
        TextEditingController();

    _clinicaController =
        TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _especialidadController.dispose();
    _telefonoController.dispose();
    _clinicaController.dispose();

    super.dispose();
  }

  void _guardar() {
    final nombre =
        _nombreController.text.trim();

    final especialidad =
        _especialidadController.text.trim();

    final telefono =
        _telefonoController.text.trim();

    final clinica =
        _clinicaController.text.trim();

    if (nombre.isEmpty ||
        especialidad.isEmpty ||
        telefono.isEmpty ||
        clinica.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa todos los campos.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'nombre': nombre,
      'especialidad': especialidad,
      'telefono': telefono,
      'clinica': clinica,
    });
  }

  InputDecoration _decoracion({
    required String label,
    required String hint,
    required IconData icono,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icono,
        color: Colors.teal,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.teal,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      title: Row(
        children: [
          Icon(
            Icons.person_add_alt_1,
            color: Colors.teal.shade700,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Nuevo veterinario',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'El veterinario se agregará al '
              'catálogo de PetCare.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: _nombreController,
              textCapitalization:
                  TextCapitalization.words,
              decoration: _decoracion(
                label: 'Nombre del veterinario',
                hint: 'Ej. Dra. Ana Torres',
                icono: Icons.person_outline,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  _especialidadController,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration: _decoracion(
                label: 'Especialidad',
                hint: 'Ej. Medicina veterinaria',
                icono: Icons.school_outlined,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: _decoracion(
                label: 'Teléfono',
                hint: 'Ej. 099 123 4567',
                icono: Icons.phone_outlined,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _clinicaController,
              textCapitalization:
                  TextCapitalization.words,
              decoration: _decoracion(
                label: 'Clínica o veterinaria',
                hint: 'Ej. Clínica Animal Care',
                icono:
                    Icons.local_hospital_outlined,
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
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          onPressed: _guardar,
          icon: const Icon(
            Icons.save_outlined,
          ),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
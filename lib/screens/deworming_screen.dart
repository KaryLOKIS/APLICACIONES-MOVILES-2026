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
  State<DewormingScreen> createState() => _DewormingScreenState();
}

class _DewormingScreenState extends State<DewormingScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;

  List<Map<String, dynamic>> _desparasitaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDesparasitaciones();
  }

  Future<void> _cargarDesparasitaciones() async {
    if (mounted) {
      setState(() {
        _cargando = true;
      });
    }

    try {
      final resultados =
          await _databaseService.obtenerDesparasitacionesPorMascota(
        widget.petId,
      );

      if (!mounted) return;

      setState(() {
        _desparasitaciones = resultados
            .map((item) => Map<String, dynamic>.from(item))
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
            'No se pudieron cargar las desparasitaciones: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _mostrarFormulario({
    Map<String, dynamic>? desparasitacion,
  }) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _FormularioDesparasitacionDialog(
          desparasitacion: desparasitacion,
        );
      },
    );

    if (resultado == null) return;

    try {
      if (desparasitacion == null) {
        await _databaseService.insertarDesparasitacion(
          petId: widget.petId,
          tipo: resultado['tipo'] as String,
          fechaAplicacion: resultado['fecha_aplicacion'] as String,

          // Se conserva vacío únicamente para mantener
          // compatibilidad con DatabaseService.
          proximaDosis: '',

          veterinario: resultado['veterinario'] as String,
          observaciones: resultado['observaciones'] as String,
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
          fechaAplicacion: resultado['fecha_aplicacion'] as String,

          // Se conserva vacío únicamente para mantener
          // compatibilidad con DatabaseService.
          proximaDosis: '',

          veterinario: resultado['veterinario'] as String,
          observaciones: resultado['observaciones'] as String,
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
        SnackBar(
          content: Text(
            'No se pudo guardar la desparasitación: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarDesparasitacion(
    Map<String, dynamic> desparasitacion,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Eliminar desparasitación',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '¿Deseas eliminar el registro de '
            '"${desparasitacion['tipo']}"?',
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
        SnackBar(
          content: Text(
            'No se pudo eliminar la desparasitación: $e',
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
      final dateTime = DateTime.parse(fecha);

      final dia = dateTime.day.toString().padLeft(2, '0');
      final mes = dateTime.month.toString().padLeft(2, '0');

      return '$dia/$mes/${dateTime.year}';
    } catch (_) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(
          'Desparasitación de ${widget.petName}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () {
          _mostrarFormulario();
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Desparasitar',
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
              onRefresh: _cargarDesparasitaciones,
              child: _desparasitaciones.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 80),
                        Icon(
                          Icons.medication_outlined,
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
                          '${widget.petName} para llevar un '
                          'mejor control de su salud.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            _mostrarFormulario();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Registrar desparasitación',
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
                      itemCount: _desparasitaciones.length,
                      itemBuilder: (context, index) {
                        final registro =
                            _desparasitaciones[index];

                        final producto =
                            registro['tipo']?.toString() ??
                                'Producto';

                        final veterinario =
                            registro['veterinario']
                                    ?.toString() ??
                                '';

                        final observaciones =
                            registro['observaciones']
                                    ?.toString() ??
                                '';

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
                                color: Colors.black.withValues(
                                  alpha: 0.06,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
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
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration:
                                          BoxDecoration(
                                        color: Colors
                                            .orange.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons
                                            .medication_outlined,
                                        color: Colors
                                            .orange.shade700,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            producto,
                                            style:
                                                const TextStyle(
                                              fontSize: 18,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
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
                                        if (value ==
                                            'editar') {
                                          _mostrarFormulario(
                                            desparasitacion:
                                                registro,
                                          );
                                        }

                                        if (value ==
                                            'eliminar') {
                                          _eliminarDesparasitacion(
                                            registro,
                                          );
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'editar',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .edit_outlined,
                                                color:
                                                    Colors.teal,
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
                                  color: Colors.grey.shade200,
                                ),

                                const SizedBox(height: 10),

                                _dato(
                                  icono: Icons
                                      .calendar_today_outlined,
                                  titulo: 'Aplicación',
                                  valor: _formatearFecha(
                                    registro[
                                            'fecha_aplicacion']
                                        ?.toString(),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                _dato(
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
                                  _dato(
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

  Widget _dato({
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
          color: Colors.teal.shade700,
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
  final DatabaseService _databaseService =
      DatabaseService.instance;

  static const String _agregarProducto =
      '__agregar_producto__';

  static const String _agregarVeterinario =
      '__agregar_veterinario__';

  final TextEditingController _nuevoProductoController =
      TextEditingController();

  final TextEditingController _observacionesController =
      TextEditingController();

  final List<String> _catalogoProductos = const [
    'Drontal',
    'Milbemax',
    'Endogard',
    'NexGard Spectra',
    'Bravecto Plus',
  ];

  List<Map<String, dynamic>> _veterinarios = [];

  String? _productoSeleccionado;
  String? _veterinarioSeleccionado;

  DateTime? _fechaAplicacion;

  bool _mostrarNuevoProducto = false;
  bool _guardandoVeterinario = false;
  bool _cargandoVeterinarios = true;

  @override
  void initState() {
    super.initState();

    final registro = widget.desparasitacion;

    if (registro != null) {
      final producto =
          registro['tipo']?.toString().trim() ?? '';

      final opcionExistente =
          _buscarOpcionProducto(producto);

      if (opcionExistente != null) {
        _productoSeleccionado = opcionExistente;
      } else if (producto.isNotEmpty) {
        _productoSeleccionado = _agregarProducto;
        _mostrarNuevoProducto = true;
        _nuevoProductoController.text = producto;
      }

      _observacionesController.text =
          registro['observaciones']?.toString() ?? '';

      _veterinarioSeleccionado =
          registro['veterinario']?.toString();

      final fechaAplicacion =
          registro['fecha_aplicacion']?.toString();

      if (fechaAplicacion != null &&
          fechaAplicacion.isNotEmpty) {
        _fechaAplicacion =
            DateTime.tryParse(fechaAplicacion);
      }
    }

    _cargarVeterinarios();
  }

  String? _buscarOpcionProducto(String producto) {
    final normalizado =
        producto.trim().toLowerCase();

    for (final opcion in _catalogoProductos) {
      if (opcion.toLowerCase() == normalizado) {
        return opcion;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _nuevoProductoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarVeterinarios() async {
    try {
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

        final seleccionado =
            _veterinarioSeleccionado;

        if (seleccionado != null &&
            seleccionado.isNotEmpty) {
          final existe = _veterinarios.any(
            (item) =>
                item['nombre']?.toString() ==
                seleccionado,
          );

          if (!existe) {
            _veterinarioSeleccionado = null;
          }
        }

        _cargandoVeterinarios = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoVeterinarios = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron cargar los veterinarios.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _seleccionarFechaAplicacion() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate:
          _fechaAplicacion ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Fecha de aplicación',
      confirmText: 'Seleccionar',
      cancelText: 'Cancelar',
    );

    if (seleccionada == null || !mounted) {
      return;
    }

    setState(() {
      _fechaAplicacion = seleccionada;
    });
  }

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

  Future<void> _agregarVeterinarioNuevo() async {
    final resultado =
        await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const _NuevoVeterinarioDialog();
      },
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
    String producto;

    if (_productoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona un producto o medicamento.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_productoSeleccionado == _agregarProducto) {
      producto =
          _nuevoProductoController.text.trim();

      if (producto.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Escribe el nombre del nuevo producto.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      producto = _productoSeleccionado!;
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
      'tipo': producto,
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
    final esEdicion =
        widget.desparasitacion != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.medication_outlined,
            color: Colors.teal.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              esEdicion
                  ? 'Editar desparasitación'
                  : 'Registrar desparasitación',
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
              'Completa la información del tratamiento.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // PRODUCTO
            // =================================================

            DropdownButtonFormField<String>(
              initialValue:
                  _productoSeleccionado,
              isExpanded: true,
              decoration: _decoracionCampo(
                label: 'Producto o medicamento',
                icono: Icons.medication_outlined,
                hint: 'Seleccionar producto',
              ),
              items: [
                ..._catalogoProductos.map(
                  (producto) {
                    return DropdownMenuItem<String>(
                      value: producto,
                      child: Text(
                        producto,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),

                const DropdownMenuItem<String>(
                  value: _agregarProducto,
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
                          'Agregar nuevo producto',
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _productoSeleccionado = value;

                  if (value == _agregarProducto) {
                    _mostrarNuevoProducto = true;
                  } else {
                    _mostrarNuevoProducto = false;
                    _nuevoProductoController.clear();
                  }
                });
              },
            ),

            if (_mostrarNuevoProducto) ...[
              const SizedBox(height: 12),
              TextField(
                controller:
                    _nuevoProductoController,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: _decoracionCampo(
                  label: 'Nombre del producto',
                  icono: Icons.edit_outlined,
                  hint: 'Escribe el nombre',
                ),
              ),
            ],

            const SizedBox(height: 14),

            // =================================================
            // VETERINARIO
            // =================================================

            _cargandoVeterinarios
                ? Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade400,
                      ),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Cargando veterinarios...',
                        ),
                      ],
                    ),
                  )
                : DropdownButtonFormField<String>(
                    initialValue:
                        _veterinarioSeleccionado,
                    isExpanded: true,
                    decoration: _decoracionCampo(
                      label: 'Veterinario',
                      icono:
                          Icons.medical_services,
                      hint:
                          'Seleccionar veterinario',
                    ),
                    items: [
                      ..._veterinarios.map(
                        (veterinario) {
                          final nombre =
                              veterinario['nombre']
                                      ?.toString() ??
                                  '';

                          final especialidad =
                              veterinario[
                                          'especialidad']
                                      ?.toString() ??
                                  '';

                          return DropdownMenuItem<
                              String>(
                            value: nombre,
                            child: Text(
                              especialidad.isEmpty
                                  ? nombre
                                  : '$nombre · '
                                      '$especialidad',
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),

                      const DropdownMenuItem<String>(
                        value:
                            _agregarVeterinario,
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
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style: TextStyle(
                                  color: Colors.teal,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged:
                        _guardandoVeterinario
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
                    '${_formatearFecha(_fechaAplicacion)}',
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
              maxLines: 3,
              textCapitalization:
                  TextCapitalization.sentences,
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
          label: Text(
            esEdicion
                ? 'Guardar cambios'
                : 'Guardar',
          ),
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
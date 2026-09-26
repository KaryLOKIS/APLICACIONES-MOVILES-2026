import 'package:flutter/material.dart';

import '../services/database_service.dart';

class VeterinariansScreen extends StatefulWidget {
  const VeterinariansScreen({super.key});

  @override
  State<VeterinariansScreen> createState() =>
      _VeterinariansScreenState();
}

class _VeterinariansScreenState
    extends State<VeterinariansScreen> {
  final DatabaseService _databaseService =
      DatabaseService.instance;

  List<Map<String, dynamic>> _veterinarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarVeterinarios();
  }

  Future<void> _cargarVeterinarios() async {
    setState(() {
      _cargando = true;
    });

    try {
      final resultados =
          await _databaseService.obtenerVeterinarios();

      if (!mounted) return;

      setState(() {
        _veterinarios = resultados
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
            'No se pudieron cargar los veterinarios: $e',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _mostrarFormularioVeterinario({
    Map<String, dynamic>? veterinario,
  }) async {
    final resultado =
        await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return _FormularioVeterinarioDialog(
          veterinario: veterinario,
        );
      },
    );

    if (resultado == null) return;

    try {
      if (veterinario == null) {
        await _databaseService.insertarVeterinario(
          nombre: resultado['nombre']!,
          especialidad: resultado['especialidad']!,
          telefono: resultado['telefono']!,
          clinica: resultado['clinica']!,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veterinario agregado correctamente.',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        await _databaseService.actualizarVeterinario(
          id: veterinario['id'] as String,
          nombre: resultado['nombre']!,
          especialidad: resultado['especialidad']!,
          telefono: resultado['telefono']!,
          clinica: resultado['clinica']!,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Información del veterinario actualizada.',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }

      await _cargarVeterinarios();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la información: $e',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _eliminarVeterinario(
    Map<String, dynamic> veterinario,
  ) async {
    final nombre = veterinario['nombre'] as String? ?? '';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Eliminar veterinario',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '¿Deseas eliminar a $nombre del catálogo de veterinarios?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
      await _databaseService.eliminarVeterinario(
        veterinario['id'] as String,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veterinario eliminado correctamente.',
          ),
          backgroundColor: Colors.teal,
        ),
      );

      await _cargarVeterinarios();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar el veterinario: $e',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
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
          'Mis veterinarios',
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
              onRefresh: _cargarVeterinarios,
              child: _veterinarios.isEmpty
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
                          'No tienes veterinarios registrados',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Agrega los profesionales que atienden a tus mascotas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        18,
                        16,
                        100,
                      ),
                      itemCount: _veterinarios.length,
                      itemBuilder: (context, index) {
                        final veterinario =
                            _veterinarios[index];

                        final nombre =
                            veterinario['nombre']
                                    as String? ??
                                'Sin nombre';

                        final especialidad =
                            veterinario['especialidad']
                                    as String? ??
                                'Sin especialidad';

                        final telefono =
                            veterinario['telefono']
                                    as String? ??
                                'Sin teléfono';

                        final clinica =
                            veterinario['clinica']
                                    as String? ??
                                'Sin clínica';

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
                                    .withValues(alpha: 0.07),
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
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.teal.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons
                                            .medical_services,
                                        color:
                                            Colors.teal.shade700,
                                        size: 30,
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
                                            nombre,
                                            style:
                                                const TextStyle(
                                              fontSize: 18,
                                              fontWeight:
                                                  FontWeight.bold,
                                              color:
                                                  Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            especialidad,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: Colors
                                                  .teal.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color:
                                            Colors.grey.shade600,
                                      ),
                                      onSelected: (opcion) {
                                        if (opcion == 'editar') {
                                          _mostrarFormularioVeterinario(
                                            veterinario:
                                                veterinario,
                                          );
                                        }

                                        if (opcion == 'eliminar') {
                                          _eliminarVeterinario(
                                            veterinario,
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
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
                                        const PopupMenuItem(
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
                                  height: 1,
                                ),
                                const SizedBox(height: 14),
                                _DatoVeterinario(
                                  icon: Icons.local_hospital_outlined,
                                  texto: clinica,
                                ),
                                const SizedBox(height: 10),
                                _DatoVeterinario(
                                  icon: Icons.phone_outlined,
                                  texto: telefono,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Agregar veterinario',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () {
          _mostrarFormularioVeterinario();
        },
      ),
    );
  }
}

class _DatoVeterinario extends StatelessWidget {
  const _DatoVeterinario({
    required this.icon,
    required this.texto,
  });

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.teal.shade600,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormularioVeterinarioDialog
    extends StatefulWidget {
  const _FormularioVeterinarioDialog({
    this.veterinario,
  });

  final Map<String, dynamic>? veterinario;

  @override
  State<_FormularioVeterinarioDialog> createState() =>
      _FormularioVeterinarioDialogState();
}

class _FormularioVeterinarioDialogState
    extends State<_FormularioVeterinarioDialog> {
  late final TextEditingController _nombreController;
  late final TextEditingController _especialidadController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _clinicaController;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: widget.veterinario?['nombre'] as String? ?? '',
    );

    _especialidadController = TextEditingController(
      text:
          widget.veterinario?['especialidad']
              as String? ??
          '',
    );

    _telefonoController = TextEditingController(
      text:
          widget.veterinario?['telefono'] as String? ?? '',
    );

    _clinicaController = TextEditingController(
      text:
          widget.veterinario?['clinica'] as String? ?? '',
    );
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
    final nombre = _nombreController.text.trim();
    final especialidad =
        _especialidadController.text.trim();
    final telefono = _telefonoController.text.trim();
    final clinica = _clinicaController.text.trim();

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

  @override
  Widget build(BuildContext context) {
    final editando = widget.veterinario != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      title: Row(
        children: [
          Icon(
            editando
                ? Icons.edit_outlined
                : Icons.medical_services_outlined,
            color: Colors.teal.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              editando
                  ? 'Editar veterinario'
                  : 'Nuevo veterinario',
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
            TextField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre del veterinario',
                hintText: 'Ej. Dra. Ana Torres',
                prefixIcon: const Icon(
                  Icons.person_outline,
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
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _especialidadController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Especialidad',
                hintText: 'Ej. Medicina veterinaria',
                prefixIcon: const Icon(
                  Icons.school_outlined,
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
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono',
                hintText: 'Ej. 099 123 4567',
                prefixIcon: const Icon(
                  Icons.phone_outlined,
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
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _clinicaController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Clínica o veterinaria',
                hintText: 'Ej. Clínica Animal Care',
                prefixIcon: const Icon(
                  Icons.local_hospital_outlined,
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
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
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
              color: Colors.grey.shade700,
            ),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _guardar,
          icon: const Icon(Icons.save_outlined),
          label: Text(
            editando ? 'Guardar cambios' : 'Guardar',
          ),
        ),
      ],
    );
  }
}
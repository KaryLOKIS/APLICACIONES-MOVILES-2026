import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../repositories/pet_repository.dart';
import '../services/database_service.dart';
import 'deworming_screen.dart';
import 'health_history_screen.dart';
import 'vaccines_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final String id;
  final String nombre;
  final String especie;
  final String raza;
  final int edad;

  const PetDetailScreen({
    super.key,
    required this.id,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.edad,
  });

  @override
  State<PetDetailScreen> createState() =>
      _PetDetailScreenState();
}

class _PetDetailScreenState
    extends State<PetDetailScreen> {
  final DatabaseService _databaseService =
      DatabaseService.instance;

  final PetRepository _petRepository =
      PetRepository();

  bool _cargando = true;

  double? _peso;
  String _alergias = '';

  @override
  void initState() {
    super.initState();
    _cargarInformacionMascota();
  }

  // =========================================================
  // CARGAR INFORMACIÓN DE LA MASCOTA
  // =========================================================

  Future<void> _cargarInformacionMascota() async {
    try {
      final mascotas =
          await _databaseService.obtenerMascotas();

      Map<String, dynamic>? mascotaEncontrada;

      for (final mascota in mascotas) {
        if (mascota.id == widget.id) {
          mascotaEncontrada = mascota.toMap();
          break;
        }
      }

      if (!mounted) {
        return;
      }

      if (mascotaEncontrada == null) {
        setState(() {
          _cargando = false;
        });
        return;
      }

      final pesoDb = mascotaEncontrada['peso'];

      setState(() {
        _peso = pesoDb == null
            ? null
            : (pesoDb as num).toDouble();

        _alergias =
            mascotaEncontrada?['alergias']
                    ?.toString()
                    .trim() ??
                '';

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
            'No se pudo cargar la información de la mascota: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // EDITAR PESO Y ALERGIAS
  // =========================================================

  Future<void> _editarInformacionGeneral() async {
    final resultado =
        await showDialog<_InformacionMascotaResultado>(
      context: context,
      builder: (context) =>
          _EditarInformacionMascotaDialog(
        pesoActual: _peso,
        alergiasActuales: _alergias,
      ),
    );

    if (resultado == null) {
      return;
    }

    try {
      final mascotaActualizada = Pet(
        id: widget.id,
        nombre: widget.nombre,
        especie: widget.especie,
        raza: widget.raza,
        edad: widget.edad,
        peso: resultado.peso,
        alergias: resultado.alergias.trim(),
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
        deleted: false,
      );

      final mascotaGuardada =
          await _petRepository.actualizarMascota(
        mascotaActualizada,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _peso = mascotaGuardada.peso;
        _alergias =
            mascotaGuardada.alergias?.trim() ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.teal,
          content: Text(
            'Información de la mascota actualizada',
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
            'No se pudo actualizar la información: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // FORMATEAR PESO
  // =========================================================

  String _formatearPeso() {
    if (_peso == null) {
      return 'Sin registrar';
    }

    if (_peso! % 1 == 0) {
      return '${_peso!.toInt()} kg';
    }

    return '${_peso!.toStringAsFixed(1)} kg';
  }

  // =========================================================
  // TARJETA PRINCIPAL
  // =========================================================

  Widget _tarjetaPrincipal() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
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
                size: 40,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nombre,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.especie,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.raza} · ${widget.edad} años',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
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
  // INFORMACIÓN GENERAL
  // =========================================================

  Widget _informacionGeneral() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Información general',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _editarInformacionGeneral,
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
              ),
              label: const Text('Editar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
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
          child: Column(
            children: [
              _filaInformacion(
                icono: Icons.pets_outlined,
                titulo: 'Raza',
                valor: widget.raza.trim().isEmpty
                    ? 'Sin registrar'
                    : widget.raza,
                color: Colors.teal,
              ),
              _separador(),
              _filaInformacion(
                icono: Icons.monitor_weight_outlined,
                titulo: 'Peso',
                valor: _formatearPeso(),
                color: Colors.blue,
              ),
              _separador(),
              _filaInformacion(
                icono:
                    Icons.health_and_safety_outlined,
                titulo: 'Alergias',
                valor: _alergias.isEmpty
                    ? 'Ninguna conocida'
                    : _alergias,
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filaInformacion({
    required IconData icono,
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icono,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _separador() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }

  // =========================================================
  // OPCIÓN DE SALUD
  // =========================================================

  Widget _opcionSalud({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color:
                      color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icono,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade500,
              ),
            ],
          ),
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
        title: Text(widget.nombre),
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
              onRefresh: _cargarInformacionMascota,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // =====================================
                    // MASCOTA
                    // =====================================

                    _tarjetaPrincipal(),

                    const SizedBox(height: 24),

                    // =====================================
                    // INFORMACIÓN GENERAL
                    // =====================================

                    _informacionGeneral(),

                    const SizedBox(height: 28),

                    // =====================================
                    // SALUD DE MI MASCOTA
                    // =====================================

                    const Text(
                      'Salud de mi mascota',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // =====================================
                    // VACUNAS
                    // =====================================

                    _opcionSalud(
                      icono: Icons.vaccines,
                      titulo: 'Vacunas',
                      descripcion:
                          'Consulta y registra las vacunas de tu mascota',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VaccinesScreen(
                              petId: widget.id,
                              petName: widget.nombre,
                            ),
                          ),
                        );
                      },
                    ),

                    // =====================================
                    // DESPARASITACIÓN
                    // =====================================

                    _opcionSalud(
                      icono: Icons.medical_services,
                      titulo: 'Desparasitación',
                      descripcion:
                          'Registra y consulta las desparasitaciones realizadas',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DewormingScreen(
                              petId: widget.id,
                              petName: widget.nombre,
                            ),
                          ),
                        );
                      },
                    ),

                    // =====================================
                    // HISTORIAL DE SALUD
                    // =====================================

                    _opcionSalud(
                      icono:
                          Icons.health_and_safety,
                      titulo: 'Historial de salud',
                      descripcion:
                          'Consulta los eventos y antecedentes médicos de tu mascota',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HealthHistoryScreen(
                              petId: widget.id,
                              petName: widget.nombre,
                              especie: widget.especie,
                              raza: widget.raza,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
    );
  }
}

// ===========================================================
// RESULTADO DEL FORMULARIO
// ===========================================================

class _InformacionMascotaResultado {
  final double? peso;
  final String alergias;

  const _InformacionMascotaResultado({
    required this.peso,
    required this.alergias,
  });
}

// ===========================================================
// DIÁLOGO PARA EDITAR PESO Y ALERGIAS
// ===========================================================

class _EditarInformacionMascotaDialog
    extends StatefulWidget {
  final double? pesoActual;
  final String alergiasActuales;

  const _EditarInformacionMascotaDialog({
    required this.pesoActual,
    required this.alergiasActuales,
  });

  @override
  State<_EditarInformacionMascotaDialog>
      createState() =>
          _EditarInformacionMascotaDialogState();
}

class _EditarInformacionMascotaDialogState
    extends State<_EditarInformacionMascotaDialog> {
  late final TextEditingController
      _pesoController;

  late final TextEditingController
      _alergiasController;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    String pesoInicial = '';

    if (widget.pesoActual != null) {
      if (widget.pesoActual! % 1 == 0) {
        pesoInicial =
            widget.pesoActual!.toInt().toString();
      } else {
        pesoInicial =
            widget.pesoActual!.toStringAsFixed(1);
      }
    }

    _pesoController =
        TextEditingController(
      text: pesoInicial,
    );

    _alergiasController =
        TextEditingController(
      text: widget.alergiasActuales,
    );
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _alergiasController.dispose();
    super.dispose();
  }

  // =========================================================
  // GUARDAR
  // =========================================================

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final textoPeso =
        _pesoController.text
            .trim()
            .replaceAll(',', '.');

    final double? peso = textoPeso.isEmpty
        ? null
        : double.tryParse(textoPeso);

    Navigator.pop(
      context,
      _InformacionMascotaResultado(
        peso: peso,
        alergias:
            _alergiasController.text.trim(),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titlePadding:
          const EdgeInsets.fromLTRB(
        24,
        22,
        24,
        0,
      ),
      contentPadding:
          const EdgeInsets.fromLTRB(
        24,
        18,
        24,
        8,
      ),
      actionsPadding:
          const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        14,
      ),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pets,
              color: Colors.teal,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Información general',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _pesoController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Peso',
                  hintText: 'Ej. 12.5',
                  suffixText: 'kg',
                  prefixIcon: const Icon(
                    Icons.monitor_weight_outlined,
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
                validator: (value) {
                  final texto =
                      value?.trim() ?? '';

                  if (texto.isEmpty) {
                    return null;
                  }

                  final numero = double.tryParse(
                    texto.replaceAll(',', '.'),
                  );

                  if (numero == null) {
                    return 'Ingresa un peso válido';
                  }

                  if (numero <= 0) {
                    return 'El peso debe ser mayor a 0';
                  }

                  if (numero > 500) {
                    return 'Revisa el peso ingresado';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller:
                    _alergiasController,
                textCapitalization:
                    TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Alergias',
                  hintText:
                      'Ej. Pollo, medicamentos o ninguna',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding:
                        EdgeInsets.only(
                      bottom: 45,
                    ),
                    child: Icon(
                      Icons
                          .health_and_safety_outlined,
                    ),
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

              const SizedBox(height: 8),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 17,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Si no tiene alergias conocidas, puedes dejar este campo vacío.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context),
          child: const Text(
            'Cancelar',
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          onPressed: _guardar,
          icon: const Icon(
            Icons.save_outlined,
            size: 19,
          ),
          label: const Text(
            'Guardar',
          ),
        ),
      ],
    );
  }
}
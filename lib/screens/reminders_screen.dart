import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../services/database_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() =>
      _RemindersScreenState();
}

class _RemindersScreenState
    extends State<RemindersScreen> {
  final DatabaseService _databaseService =
      DatabaseService.instance;

  List<Map<String, dynamic>> _recordatorios = [];

  List<Pet> _mascotas = [];

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // =========================================================
  // CARGAR DATOS
  // =========================================================

  Future<void> _cargarDatos() async {
    try {
      final resultados = await Future.wait([
        _databaseService.obtenerRecordatorios(),
        _databaseService.obtenerMascotas(),
      ]);

      if (!mounted) {
        return;
      }

      final recordatorios =
          resultados[0] as List<Map<String, dynamic>>;

      final mascotas =
          resultados[1] as List<Pet>;

      mascotas.sort(
        (a, b) => a.nombre.compareTo(b.nombre),
      );

      recordatorios.sort(
        (a, b) {
          final fechaA = _convertirFecha(
            a['fecha'] as String,
          );

          final fechaB = _convertirFecha(
            b['fecha'] as String,
          );

          return fechaA.compareTo(fechaB);
        },
      );

      setState(() {
        _recordatorios = recordatorios;

        _mascotas = mascotas
            .where(
              (mascota) => !mascota.deleted,
            )
            .toList();

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
            'No se pudieron cargar los datos: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // CONVERTIR FECHA DD/MM/YYYY
  // =========================================================

  DateTime _convertirFecha(String fecha) {
    final partes = fecha.split('/');

    if (partes.length != 3) {
      return DateTime(9999);
    }

    final dia = int.tryParse(partes[0]) ?? 1;
    final mes = int.tryParse(partes[1]) ?? 1;
    final anio = int.tryParse(partes[2]) ?? 9999;

    return DateTime(
      anio,
      mes,
      dia,
    );
  }

  // =========================================================
  // FECHA SIN HORA
  // =========================================================

  DateTime _fechaSinHora(DateTime fecha) {
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    );
  }

  // =========================================================
  // ESTADO DEL RECORDATORIO
  // =========================================================

  String _estadoRecordatorio(String fecha) {
    final fechaRecordatorio =
        _fechaSinHora(
      _convertirFecha(fecha),
    );

    final hoy =
        _fechaSinHora(DateTime.now());

    if (fechaRecordatorio.isBefore(hoy)) {
      return 'Vencido';
    }

    if (fechaRecordatorio.isAtSameMomentAs(hoy)) {
      return 'Hoy';
    }

    return 'Próximo';
  }

  // =========================================================
  // COLOR DEL ESTADO
  // =========================================================

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Vencido':
        return Colors.red;

      case 'Hoy':
        return Colors.orange;

      default:
        return Colors.teal;
    }
  }

  // =========================================================
  // ICONO SEGÚN TIPO
  // =========================================================

  IconData _iconoPorTipo(
    String tipo,
  ) {
    switch (tipo) {
      case 'Vacuna':
        return Icons.vaccines;

      case 'Desparasitación':
        return Icons.medical_services;

      case 'Cita veterinaria':
        return Icons.medical_information;

      default:
        return Icons.notifications_active;
    }
  }

  // =========================================================
  // COLOR SEGÚN TIPO
  // =========================================================

  Color _colorPorTipo(
    String tipo,
  ) {
    switch (tipo) {
      case 'Vacuna':
        return Colors.teal;

      case 'Desparasitación':
        return Colors.orange;

      case 'Cita veterinaria':
        return Colors.blue;

      default:
        return Colors.purple;
    }
  }

  // =========================================================
  // AGREGAR RECORDATORIO
  // =========================================================

  Future<void> _agregarRecordatorio() async {
    if (_mascotas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero debes registrar una mascota.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final resultado =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        DateTime fechaSeleccionada =
            DateTime.now();

        Pet mascotaSeleccionada =
            _mascotas.first;

        String tipoSeleccionado =
            'Vacuna';

        final descripcionController =
            TextEditingController();

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final esOtro =
                tipoSeleccionado == 'Otro';

            return AlertDialog(
              title: const Text(
                'Nuevo recordatorio',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [

                    // =================================================
                    // MASCOTA
                    // =================================================

                    DropdownButtonFormField<Pet>(
                      initialValue:
                          mascotaSeleccionada,
                      decoration:
                          const InputDecoration(
                        labelText: 'Mascota',
                        prefixIcon:
                            Icon(Icons.pets),
                        border:
                            OutlineInputBorder(),
                      ),
                      items: _mascotas
                          .map(
                            (mascota) =>
                                DropdownMenuItem<
                                    Pet>(
                              value: mascota,
                              child: Text(
                                mascota.nombre,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged:
                          (mascota) {
                        if (mascota == null) {
                          return;
                        }

                        setDialogState(() {
                          mascotaSeleccionada =
                              mascota;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    // =================================================
                    // TIPO
                    // =================================================

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                          tipoSeleccionado,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Tipo de recordatorio',
                        prefixIcon:
                            Icon(
                          Icons.category_outlined,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Vacuna',
                          child: Row(
                            children: [
                              Icon(
                                Icons.vaccines,
                                size: 20,
                                color:
                                    Colors.teal,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Vacuna',
                              ),
                            ],
                          ),
                        ),

                        DropdownMenuItem(
                          value:
                              'Desparasitación',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .medical_services,
                                size: 20,
                                color:
                                    Colors.orange,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Desparasitación',
                              ),
                            ],
                          ),
                        ),

                        DropdownMenuItem(
                          value:
                              'Cita veterinaria',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .medical_information,
                                size: 20,
                                color:
                                    Colors.blue,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Cita veterinaria',
                              ),
                            ],
                          ),
                        ),

                        DropdownMenuItem(
                          value: 'Otro',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .notifications_active,
                                size: 20,
                                color:
                                    Colors.purple,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Otro',
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged:
                          (tipo) {
                        if (tipo == null) {
                          return;
                        }

                        setDialogState(() {
                          tipoSeleccionado =
                              tipo;
                        });
                      },
                    ),

                    // =================================================
                    // DESCRIPCIÓN PARA OTRO
                    // =================================================

                    if (esOtro) ...[
                      const SizedBox(
                        height: 15,
                      ),

                      TextField(
                        controller:
                            descripcionController,
                        textCapitalization:
                            TextCapitalization.sentences,
                        maxLines: 2,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Descripción',
                          hintText:
                              'Ej.: Dar medicamento',
                          prefixIcon:
                              Icon(
                            Icons.edit_note,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 15,
                    ),

                    // =================================================
                    // FECHA
                    // =================================================

                    InkWell(
                      onTap: () async {
                        final fecha =
                            await showDatePicker(
                          context: context,
                          initialDate:
                              fechaSeleccionada,
                          firstDate:
                              DateTime.now(),
                          lastDate:
                              DateTime(2035),
                        );

                        if (fecha == null) {
                          return;
                        }

                        setDialogState(() {
                          fechaSeleccionada =
                              fecha;
                        });
                      },
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(
                          labelText: 'Fecha',
                          prefixIcon:
                              Icon(
                            Icons.calendar_month,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        child: Text(
                          '${fechaSeleccionada.day.toString().padLeft(2, '0')}/'
                          '${fechaSeleccionada.month.toString().padLeft(2, '0')}/'
                          '${fechaSeleccionada.year}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // =======================================================
              // BOTONES
              // =======================================================

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child:
                      const Text(
                    'Cancelar',
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    final descripcion =
                        descripcionController
                            .text
                            .trim();

                    if (tipoSeleccionado ==
                            'Otro' &&
                        descripcion.isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Escribe una descripción.',
                          ),
                        ),
                      );

                      return;
                    }

                    final titulo =
                        tipoSeleccionado ==
                                'Otro'
                            ? descripcion
                            : tipoSeleccionado;

                    final fecha =
                        '${fechaSeleccionada.day.toString().padLeft(2, '0')}/'
                        '${fechaSeleccionada.month.toString().padLeft(2, '0')}/'
                        '${fechaSeleccionada.year}';

                    Navigator.of(
                      dialogContext,
                    ).pop({
                      'titulo': titulo,
                      'mascota':
                          mascotaSeleccionada
                              .nombre,
                      'fecha': fecha,
                      'tipo':
                          tipoSeleccionado,
                    });
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.teal,
                    foregroundColor:
                        Colors.white,
                  ),
                  child:
                      const Text(
                    'Guardar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted ||
        resultado == null) {
      return;
    }

    try {
      await _databaseService
          .insertarRecordatorio(
        titulo:
            resultado['titulo']
                as String,
        mascota:
            resultado['mascota']
                as String,
        fecha:
            resultado['fecha']
                as String,
        tipo:
            resultado['tipo']
                as String,
      );

      await _cargarDatos();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Recordatorio guardado correctamente.',
          ),
          backgroundColor:
              Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar el recordatorio: $e',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // ELIMINAR RECORDATORIO
  // =========================================================

  Future<void> _eliminarRecordatorio(
    int index,
  ) async {
    final recordatorio =
        _recordatorios[index];

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Eliminar recordatorio',
          ),
          content: Text(
            '¿Deseas eliminar el recordatorio '
            '"${recordatorio['titulo']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text(
                'Cancelar',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true ||
        !mounted) {
      return;
    }

    final id =
        recordatorio['id']
            as String?;

    if (id == null ||
        id.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo identificar el recordatorio.',
          ),
          backgroundColor:
              Colors.red,
        ),
      );

      return;
    }

    try {
      await _databaseService
          .eliminarRecordatorio(id);

      await _cargarDatos();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Recordatorio eliminado correctamente.',
          ),
          backgroundColor:
              Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar el recordatorio: $e',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // TARJETA
  // =========================================================

  Widget _construirRecordatorio(
    Map<String, dynamic> recordatorio,
    int index,
  ) {
    final tipo =
        recordatorio['tipo']
                as String? ??
            'Otro';

    final fecha =
        recordatorio['fecha']
                as String? ??
            '';

    final estado =
        _estadoRecordatorio(fecha);

    final colorTipo =
        _colorPorTipo(tipo);

    final colorEstado =
        _colorEstado(estado);

    return Card(
      elevation: 3,
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child:
          ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),

        leading:
            Container(
          padding:
              const EdgeInsets.all(12),
          decoration:
              BoxDecoration(
            color:
                colorTipo.withValues(
              alpha: 0.10,
            ),
            shape:
                BoxShape.circle,
          ),
          child:
              Icon(
            _iconoPorTipo(tipo),
            color:
                colorTipo,
            size: 28,
          ),
        ),

        title:
            Text(
          recordatorio['titulo']
              as String,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize:
                17,
          ),
        ),

        subtitle:
            Padding(
          padding:
              const EdgeInsets.only(
            top: 6,
          ),
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                '${recordatorio['mascota']} • $fecha',
              ),

              const SizedBox(
                height: 5,
              ),

              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          colorEstado.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child:
                        Text(
                      estado,
                      style:
                          TextStyle(
                        color:
                            colorEstado,
                        fontWeight:
                            FontWeight.bold,
                        fontSize:
                            11,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Text(
                    tipo,
                    style:
                        TextStyle(
                      color:
                          colorTipo,
                      fontWeight:
                          FontWeight.w600,
                      fontSize:
                          12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        trailing:
            IconButton(
          tooltip:
              'Eliminar',
          icon:
              const Icon(
            Icons
                .delete_outline,
            color:
                Colors.red,
          ),
          onPressed:
              () {
            _eliminarRecordatorio(
              index,
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.teal.shade50,

      appBar:
          AppBar(
        title:
            const Text(
          'Recordatorios',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        backgroundColor:
            Colors.teal,
        foregroundColor:
            Colors.white,
        centerTitle:
            true,
      ),

      body:
          _cargando
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        Colors.teal,
                  ),
                )
              : _recordatorios
                      .isEmpty
                  ? Center(
                      child:
                          Padding(
                        padding:
                            const EdgeInsets.all(
                          30,
                        ),
                        child:
                            Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons
                                  .notifications_none,
                              size:
                                  90,
                              color:
                                  Colors.teal.shade300,
                            ),

                            const SizedBox(
                              height:
                                  20,
                            ),

                            const Text(
                              'No tienes recordatorios',
                              style:
                                  TextStyle(
                                fontSize:
                                    21,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  10,
                            ),

                            const Text(
                              'Agrega un recordatorio para no olvidar los cuidados importantes de tu mascota.',
                              textAlign:
                                  TextAlign.center,
                              style:
                                  TextStyle(
                                color:
                                    Colors.black54,
                                fontSize:
                                    15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      children: [

                        const Text(
                          'Próximos recordatorios',
                          style:
                              TextStyle(
                            fontSize:
                                24,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Colors.teal,
                          ),
                        ),

                        const SizedBox(
                          height:
                              8,
                        ),

                        const Text(
                          'Mantén al día las actividades importantes para el cuidado de tus mascotas.',
                          style:
                              TextStyle(
                            color:
                                Colors.black54,
                            fontSize:
                                15,
                          ),
                        ),

                        const SizedBox(
                          height:
                              22,
                        ),

                        ...List.generate(
                          _recordatorios.length,
                          (index) =>
                              _construirRecordatorio(
                            _recordatorios[
                                index],
                            index,
                          ),
                        ),
                      ],
                    ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _agregarRecordatorio,
        backgroundColor:
            Colors.teal,
        foregroundColor:
            Colors.white,
        icon:
            const Icon(
          Icons.add_alert,
        ),
        label:
            const Text(
          'Agregar',
        ),
      ),
    );
  }
}
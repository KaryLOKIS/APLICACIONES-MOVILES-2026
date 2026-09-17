import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/pet.dart';
import '../repositories/pet_repository.dart';
import 'pet_detail_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen>
    with WidgetsBindingObserver {
  final PetRepository _repository = PetRepository();

  final Uuid _uuid = const Uuid();

  final Connectivity _connectivity = Connectivity();

  List<Pet> mascotas = [];

  bool cargando = true;
  bool conectado = true;
  bool sincronizando = false;

  DateTime? ultimaCargaLocal;

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  // =========================================================
  // INICIALIZAR
  // =========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _inicializarConexion();

    _repository.iniciarSincronizacionAutomatica();

    _cargarMascotas();
  }

  // =========================================================
  // INICIALIZAR CONEXIÓN
  // =========================================================

  Future<void> _inicializarConexion() async {
    try {
      final resultado =
          await _connectivity.checkConnectivity();

      if (!mounted) return;

      _actualizarEstadoConexion(resultado);

      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(
        _actualizarEstadoConexion,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        conectado = false;
      });
    }
  }

  // =========================================================
  // ACTUALIZAR ESTADO DE CONEXIÓN
  // =========================================================

  void _actualizarEstadoConexion(
    List<ConnectivityResult> resultado,
  ) {
    if (!mounted) return;

    final hayConexion =
        resultado.isNotEmpty &&
        !resultado.contains(
          ConnectivityResult.none,
        );

    final estabaDesconectado = !conectado;

    setState(() {
      conectado = hayConexion;
    });

    // ---------------------------------------------------------
    // SI VOLVIÓ INTERNET, CARGAR Y SINCRONIZAR
    // ---------------------------------------------------------

    if (hayConexion && estabaDesconectado) {
      _sincronizarYRecargar();
    }
  }

  // =========================================================
  // CICLO DE VIDA
  // =========================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _comprobarConexionAlRegresar();
    }
  }

  // =========================================================
  // COMPROBAR CONEXIÓN AL REGRESAR
  // =========================================================

  Future<void> _comprobarConexionAlRegresar() async {
    try {
      final resultado =
          await _connectivity.checkConnectivity();

      if (!mounted) return;

      _actualizarEstadoConexion(resultado);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        conectado = false;
      });
    }
  }

  // =========================================================
  // CARGAR MASCOTAS
  // =========================================================

  Future<void> _cargarMascotas() async {
    if (mounted) {
      setState(() {
        cargando = true;
      });
    }

    try {
      final mascotasObtenidas =
          await _repository.obtenerMascotas();

      if (!mounted) return;

      setState(() {
        mascotas = mascotasObtenidas;

        mascotas.sort(
          (a, b) =>
              a.nombre.compareTo(b.nombre),
        );

        ultimaCargaLocal = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar las mascotas: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  // =========================================================
  // SINCRONIZAR Y RECARGAR
  // =========================================================

  Future<void> _sincronizarYRecargar() async {
    if (sincronizando) {
      return;
    }

    if (mounted) {
      setState(() {
        sincronizando = true;
      });
    }

    try {
      await _repository.sincronizarPendientes();

      await _cargarMascotas();
    } finally {
      if (mounted) {
        setState(() {
          sincronizando = false;
        });
      }
    }
  }

  // =========================================================
  // MOSTRAR FORMULARIO
  // =========================================================

  Future<void> _mostrarFormularioMascota() async {
    final datos =
        await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return const _FormularioMascotaDialog();
      },
    );

    if (datos == null) return;

    final nuevaMascota = Pet(
      id: _uuid.v4(),
      nombre: datos['nombre']!,
      especie: datos['especie']!,
      raza: datos['raza']!,
      edad: int.parse(
        datos['edad']!,
      ),
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
    );

    try {
      final mascotaGuardada =
          await _repository.crearMascota(
        nuevaMascota,
      );

      if (!mounted) return;

      setState(() {
        mascotas.removeWhere(
          (item) =>
              item.id == mascotaGuardada.id,
        );

        if (!mascotaGuardada.deleted) {
          mascotas.add(mascotaGuardada);
        }

        mascotas.sort(
          (a, b) =>
              a.nombre.compareTo(b.nombre),
        );

        ultimaCargaLocal = DateTime.now();
      });

      final estaSincronizada =
          mascotaGuardada.syncStatus ==
              'synced';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estaSincronizada
                ? '${mascotaGuardada.nombre} se guardó correctamente.'
                : '${mascotaGuardada.nombre} se guardó en el dispositivo y quedó pendiente de sincronización.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la mascota: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // ELIMINAR MASCOTA
  // =========================================================

  Future<void> _eliminarMascota(
    Pet mascota,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar mascota',
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar a ${mascota.nombre}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
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
      await _repository.eliminarMascota(
        mascota.id,
      );

      if (!mounted) return;

      setState(() {
        mascotas.removeWhere(
          (item) =>
              item.id == mascota.id,
        );

        ultimaCargaLocal = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            conectado
                ? '${mascota.nombre} fue eliminada.'
                : '${mascota.nombre} fue eliminada localmente y quedó pendiente de sincronización.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar la mascota: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // ABRIR DETALLE
  // =========================================================

  Future<void> _abrirDetalleMascota(
    Pet mascota,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return PetDetailScreen(
            nombre: mascota.nombre,
            especie: mascota.especie,
            raza: mascota.raza,
            edad: mascota.edad,
          );
        },
      ),
    );
  }

  // =========================================================
  // TEXTO ÚLTIMA CARGA
  // =========================================================

  String _textoUltimaCarga() {
    if (ultimaCargaLocal == null) {
      return 'Datos guardados localmente';
    }

    final hora = TimeOfDay.fromDateTime(
      ultimaCargaLocal!,
    );

    final minuto =
        hora.minute.toString().padLeft(
              2,
              '0',
            );

    final periodo =
        hora.period == DayPeriod.am
            ? 'a. m.'
            : 'p. m.';

    final hora12 =
        hora.hourOfPeriod == 0
            ? 12
            : hora.hourOfPeriod;

    return 'Última lectura local: '
        '$hora12:$minuto $periodo';
  }

  // =========================================================
  // INDICADOR DE CONEXIÓN
  // =========================================================

  Widget _indicadorConexion() {
    if (conectado) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          0,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color:
              const Color(0xFFE8F5E9),
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color:
                const Color(0xFFA5D6A7),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFFC8E6C9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_done_outlined,
                color:
                    Color(0xFF2E7D32),
                size: 20,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conexión disponible',
                    style: TextStyle(
                      color:
                          Color(0xFF2E7D32),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    sincronizando
                        ? 'Sincronizando datos...'
                        : _textoUltimaCarga(),
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF4E6B50),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (sincronizando)
              const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFFFF3E0),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              const Color(0xFFFFCC80),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                const BoxDecoration(
              color:
                  Color(0xFFFFE0B2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_outlined,
              color:
                  Color(0xFFE65100),
              size: 20,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Sin conexión',
                  style: TextStyle(
                    color:
                        Color(0xFFE65100),
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Mostrando datos guardados en el dispositivo',
                  style: TextStyle(
                    color:
                        Color(0xFF8D5A2B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.storage_outlined,
            color:
                Color(0xFFE65100),
            size: 20,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(
      this,
    );

    _connectivitySubscription?.cancel();

    _repository
        .detenerSincronizacionAutomatica();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFE8F5F3),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF009688),
        foregroundColor:
            Colors.white,
        elevation: 0,
        title: const Text(
          'Mis mascotas',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: cargando
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _cargarMascotas,
              child: mascotas.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.all(
                        24,
                      ),
                      children: [
                        _indicadorConexion(),
                        const SizedBox(
                          height: 70,
                        ),
                        Container(
                          padding:
                              const EdgeInsets.all(
                            22,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              24,
                            ),
                          ),
                          child:
                              Column(
                            children: [
                              Container(
                                width: 82,
                                height: 82,
                                decoration:
                                    const BoxDecoration(
                                  color:
                                      Color(0xFFE0F2F1),
                                  shape:
                                      BoxShape.circle,
                                ),
                                child:
                                    const Icon(
                                  Icons.pets,
                                  size: 42,
                                  color:
                                      Color(0xFF009688),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              const Text(
                                'Aún no tienes mascotas',
                                textAlign:
                                    TextAlign.center,
                                style:
                                    TextStyle(
                                  fontSize:
                                      21,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              const Text(
                                'Agrega tu primera mascota para comenzar a llevar el control de su información.',
                                textAlign:
                                    TextAlign.center,
                                style:
                                    TextStyle(
                                  color:
                                      Colors.black54,
                                  height:
                                      1.4,
                                ),
                              ),
                              const SizedBox(
                                height: 22,
                              ),
                              FilledButton.icon(
                                onPressed:
                                    _mostrarFormularioMascota,
                                icon:
                                    const Icon(
                                  Icons.add,
                                ),
                                label:
                                    const Text(
                                  'Agregar mascota',
                                ),
                                style:
                                    FilledButton.styleFrom(
                                  backgroundColor:
                                      const Color(
                                    0xFF009688,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal:
                                        22,
                                    vertical:
                                        14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        0,
                        0,
                        0,
                        100,
                      ),
                      children: [
                        _indicadorConexion(),
                        const SizedBox(
                          height: 14,
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(
                                    alpha:
                                        0.05,
                                  ),
                                  blurRadius:
                                      10,
                                  offset:
                                      const Offset(
                                    0,
                                    4,
                                  ),
                                ),
                              ],
                            ),
                            child:
                                Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration:
                                      const BoxDecoration(
                                    color:
                                        Color(0xFFE0F2F1),
                                    shape:
                                        BoxShape.circle,
                                  ),
                                  child:
                                      const Icon(
                                    Icons.favorite,
                                    color:
                                        Color(0xFF009688),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(
                                  width: 14,
                                ),
                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tus compañeros 🐾',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              17,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Text(
                                        '${mascotas.length} ${mascotas.length == 1 ? 'mascota registrada' : 'mascotas registradas'}',
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        ...mascotas.map(
                          (mascota) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child:
                                  _TarjetaMascota(
                                mascota:
                                    mascota,
                                onTap:
                                    () {
                                  _abrirDetalleMascota(
                                    mascota,
                                  );
                                },
                                onDelete:
                                    () {
                                  _eliminarMascota(
                                    mascota,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ),
      floatingActionButton:
          FloatingActionButton(
        onPressed:
            _mostrarFormularioMascota,
        backgroundColor:
            const Color(0xFF009688),
        foregroundColor:
            Colors.white,
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}

// =============================================================
// TARJETA DE MASCOTA
// =============================================================

class _TarjetaMascota
    extends StatelessWidget {
  final Pet mascota;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TarjetaMascota({
    required this.mascota,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pendiente =
        mascota.syncStatus !=
        'synced';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFFFF7FF),
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 9,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(
            14,
            16,
            8,
            16,
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFE0F2F1),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons.pets,
                  color:
                      Color(0xFF009688),
                  size: 32,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      mascota.nombre,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      '${mascota.especie} • ${mascota.raza}',
                      style:
                          const TextStyle(
                        color:
                            Colors.black54,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Edad: ${mascota.edad} ${mascota.edad == 1 ? 'año' : 'años'}',
                      style:
                          const TextStyle(
                        color:
                            Colors.black54,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      pendiente
                          ? 'Pendiente de sincronización'
                          : 'Sincronizada con el servidor',
                      style:
                          TextStyle(
                        color: pendiente
                            ? const Color(
                                0xFFE65100,
                              )
                            : const Color(
                                0xFF009688,
                              ),
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected:
                    (value) {
                  if (value ==
                      'eliminar') {
                    onDelete();
                  }
                },
                itemBuilder:
                    (context) {
                  return const [
                    PopupMenuItem(
                      value:
                          'eliminar',
                      child:
                          Row(
                        children: [
                          Icon(
                            Icons
                                .delete_outline,
                            color:
                                Colors.red,
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
        ),
      ),
    );
  }
}

// =============================================================
// FORMULARIO
// =============================================================

class _FormularioMascotaDialog
    extends StatefulWidget {
  const _FormularioMascotaDialog();

  @override
  State<
      _FormularioMascotaDialog>
      createState() =>
          _FormularioMascotaDialogState();
}

class _FormularioMascotaDialogState
    extends State<
        _FormularioMascotaDialog> {
  final _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _nombreController;

  late final TextEditingController
      _razaController;

  late final TextEditingController
      _edadController;

  String _especie = 'Perro';

  @override
  void initState() {
    super.initState();

    _nombreController =
        TextEditingController();

    _razaController =
        TextEditingController();

    _edadController =
        TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _edadController.dispose();

    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    Navigator.pop(
      context,
      {
        'nombre':
            _nombreController.text
                .trim(),
        'especie': _especie,
        'raza':
            _razaController.text.trim(),
        'edad':
            _edadController.text.trim(),
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      title: const Text(
        'Agregar mascota',
        style: TextStyle(
          fontWeight:
              FontWeight.bold,
        ),
      ),
      content:
          SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              TextFormField(
                controller:
                    _nombreController,
                textCapitalization:
                    TextCapitalization.words,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Nombre',
                  prefixIcon:
                      Icon(
                    Icons.pets,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
                validator:
                    (value) {
                  if (value ==
                          null ||
                      value
                          .trim()
                          .isEmpty) {
                    return 'Ingresa el nombre';
                  }

                  if (value
                          .trim()
                          .length <
                      2) {
                    return 'El nombre es demasiado corto';
                  }

                  return null;
                },
              ),
              const SizedBox(
                height: 14,
              ),
              DropdownButtonFormField<
                  String>(
                initialValue:
                    _especie,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Especie',
                  prefixIcon:
                      Icon(
                    Icons
                        .category_outlined,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value:
                        'Perro',
                    child:
                        Text(
                      'Perro',
                    ),
                  ),
                  DropdownMenuItem(
                    value:
                        'Gato',
                    child:
                        Text(
                      'Gato',
                    ),
                  ),
                  DropdownMenuItem(
                    value:
                        'Otro',
                    child:
                        Text(
                      'Otro',
                    ),
                  ),
                ],
                onChanged:
                    (value) {
                  if (value ==
                      null) {
                    return;
                  }

                  setState(() {
                    _especie =
                        value;
                  });
                },
              ),
              const SizedBox(
                height: 14,
              ),
              TextFormField(
                controller:
                    _razaController,
                textCapitalization:
                    TextCapitalization.words,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Raza',
                  prefixIcon:
                      Icon(
                    Icons
                        .info_outline,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
                validator:
                    (value) {
                  if (value ==
                          null ||
                      value
                          .trim()
                          .isEmpty) {
                    return 'Ingresa la raza';
                  }

                  return null;
                },
              ),
              const SizedBox(
                height: 14,
              ),
              TextFormField(
                controller:
                    _edadController,
                keyboardType:
                    TextInputType.number,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Edad',
                  prefixIcon:
                      Icon(
                    Icons
                        .cake_outlined,
                  ),
                  suffixText:
                      'años',
                  border:
                      OutlineInputBorder(),
                ),
                validator:
                    (value) {
                  if (value ==
                          null ||
                      value
                          .trim()
                          .isEmpty) {
                    return 'Ingresa la edad';
                  }

                  final edad =
                      int.tryParse(
                    value.trim(),
                  );

                  if (edad ==
                      null) {
                    return 'Ingresa un número válido';
                  }

                  if (edad < 0 ||
                      edad > 100) {
                    return 'La edad debe estar entre 0 y 100';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
          child:
              const Text(
            'Cancelar',
          ),
        ),
        FilledButton(
          onPressed:
              _guardar,
          style:
              FilledButton.styleFrom(
            backgroundColor:
                const Color(
              0xFF009688,
            ),
          ),
          child:
              const Text(
            'Guardar',
          ),
        ),
      ],
    );
  }
}
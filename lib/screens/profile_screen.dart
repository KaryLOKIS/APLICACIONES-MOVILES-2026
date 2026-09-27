import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Dio _dio = ApiClient.instance.dio;

  bool _cargando = true;
  String? _error;

  String _nombre = '';
  String _email = '';
  String _telefono = '';

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final response = await _dio.get(
        ApiConfig.meEndpoint,
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception(
          'La respuesta del servidor no es válida.',
        );
      }

      Map<dynamic, dynamic>? usuario;

      if (data['usuario'] is Map) {
        usuario = data['usuario'] as Map;
      } else if (data['user'] is Map) {
        usuario = data['user'] as Map;
      } else if (data['datos'] is Map) {
        usuario = data['datos'] as Map;
      } else {
        usuario = data;
      }

      final nombre = _obtenerTexto(
        usuario,
        const [
          'nombre',
          'name',
          'nombre_completo',
          'full_name',
        ],
      );

      final email = _obtenerTexto(
        usuario,
        const [
          'email',
          'correo',
          'correo_electronico',
        ],
      );

      final telefono = _obtenerTexto(
        usuario,
        const [
          'telefono',
          'phone',
          'celular',
        ],
      );

      if (!mounted) return;

      setState(() {
        _nombre = nombre;
        _email = email;
        _telefono = telefono;
        _cargando = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = _mensajeDio(error);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error =
            'No fue posible cargar tu perfil.';
      });
    }
  }

  String _obtenerTexto(
    Map<dynamic, dynamic> mapa,
    List<String> claves,
  ) {
    for (final clave in claves) {
      final valor = mapa[clave];

      if (valor != null) {
        final texto = valor.toString().trim();

        if (texto.isNotEmpty &&
            texto.toLowerCase() != 'null') {
          return texto;
        }
      }
    }

    return '';
  }

  String _mensajeDio(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      final mensaje = data['mensaje'];

      if (mensaje != null &&
          mensaje.toString().trim().isNotEmpty) {
        return mensaje.toString();
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'El servidor tardó demasiado en responder.';

      case DioExceptionType.connectionError:
        return 'No fue posible conectarse con el servidor.';

      default:
        return 'No fue posible completar la operación.';
    }
  }

  String get _nombreParaMostrar {
    if (_nombre.trim().isNotEmpty) {
      return _nombre.trim();
    }

    if (_email.contains('@')) {
      final parte =
          _email.split('@').first.trim();

      if (parte.isNotEmpty) {
        return parte;
      }
    }

    return 'Usuario PetCare';
  }

  String get _inicial {
    final nombre = _nombreParaMostrar.trim();

    if (nombre.isEmpty) {
      return 'U';
    }

    return nombre[0].toUpperCase();
  }

  Future<void> _abrirEditarPerfil() async {
    final actualizado =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          nombre: _nombre,
          email: _email,
          telefono: _telefono,
        ),
      ),
    );

    if (actualizado == true) {
      await _cargarPerfil();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Perfil actualizado correctamente.',
            ),
          ),
        );
    }
  }

  void _mostrarProximamente(
    String opcion,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$opcion estará disponible próximamente.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mi perfil',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed:
                _cargando ? null : _cargarPerfil,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00796B),
        ),
      );
    }

    if (_error != null) {
      return _construirError();
    }

    return RefreshIndicator(
      color: const Color(0xFF00796B),
      onRefresh: _cargarPerfil,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          32,
        ),
        children: [
          _construirCabecera(),

          const SizedBox(height: 30),

          const Text(
            'Mis datos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),

          const SizedBox(height: 12),

          _construirTarjetaDatos(),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  _abrirEditarPerfil,
              style: FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF00796B),
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.edit_outlined,
              ),
              label: const Text(
                'Editar perfil',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Configuración',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),

          const SizedBox(height: 12),

          _construirOpcion(
            icono:
                Icons.notifications_outlined,
            titulo: 'Notificaciones',
            subtitulo:
                'Configura tus recordatorios y avisos',
            onTap: () =>
                _mostrarProximamente(
              'Notificaciones',
            ),
          ),

          const SizedBox(height: 10),

          _construirOpcion(
            icono:
                Icons.shield_outlined,
            titulo: 'Seguridad',
            subtitulo:
                'Contraseña y seguridad de tu cuenta',
            onTap: () =>
                _mostrarProximamente(
              'Seguridad',
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCabecera() {
    return Column(
      children: [
        Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(
            color:
                const Color(0xFFE0F2F1),
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  const Color(0xFF80CBC4),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _inicial,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00796B),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Text(
          _nombreParaMostrar,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: Color(0xFF263238),
          ),
        ),

        if (_email.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            _email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF78909C),
            ),
          ),
        ],
      ],
    );
  }

  Widget _construirTarjetaDatos() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _construirDato(
            icono:
                Icons.person_outline_rounded,
            titulo: 'Nombre',
            valor: _nombre.isEmpty
                ? 'Sin registrar'
                : _nombre,
          ),

          _divisor(),

          _construirDato(
            icono:
                Icons.email_outlined,
            titulo:
                'Correo electrónico',
            valor: _email.isEmpty
                ? 'Sin registrar'
                : _email,
          ),

          _divisor(),

          _construirDato(
            icono:
                Icons.phone_outlined,
            titulo: 'Teléfono',
            valor: _telefono.isEmpty
                ? 'Agregar teléfono'
                : _telefono,
            accionable:
                _telefono.isEmpty,
            onTap: _telefono.isEmpty
                ? _abrirEditarPerfil
                : null,
          ),
        ],
      ),
    );
  }

  Widget _construirDato({
    required IconData icono,
    required String titulo,
    required String valor,
    bool accionable = false,
    VoidCallback? onTap,
  }) {
    final contenido = Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFE0F2F1),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icono,
              color:
                  const Color(0xFF00796B),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    color:
                        Color(0xFF78909C),
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                    color: accionable
                        ? const Color(
                            0xFF00796B,
                          )
                        : const Color(
                            0xFF263238,
                          ),
                  ),
                ),
              ],
            ),
          ),

          if (accionable)
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF00796B),
            ),
        ],
      ),
    );

    if (onTap == null) {
      return contenido;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: contenido,
      ),
    );
  }

  Widget _divisor() {
    return const Divider(
      height: 1,
      indent: 74,
      endIndent: 18,
      color: Color(0xFFECEFF1),
    );
  }

  Widget _construirOpcion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE0F2F1,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icono,
                  color:
                      const Color(
                    0xFF00796B,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(
                          0xFF263238,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitulo,
                      style:
                          const TextStyle(
                        fontSize: 13,
                        color:
                            Color(
                          0xFF78909C,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color:
                    Color(0xFF90A4AE),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .cloud_off_outlined,
              size: 58,
              color:
                  Color(0xFF90A4AE),
            ),

            const SizedBox(height: 16),

            const Text(
              'No pudimos cargar tu perfil',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _error ??
                  'Inténtalo nuevamente.',
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color:
                    Color(0xFF78909C),
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed:
                  _cargarPerfil,
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF00796B,
                ),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label:
                  const Text(
                'Reintentar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PANTALLA EDITAR PERFIL
// ============================================================

class EditProfileScreen
    extends StatefulWidget {
  final String nombre;
  final String email;
  final String telefono;

  const EditProfileScreen({
    super.key,
    required this.nombre,
    required this.email,
    required this.telefono,
  });

  @override
  State<EditProfileScreen>
      createState() =>
          _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final Dio _dio =
      ApiClient.instance.dio;

  late final TextEditingController
      _nombreController;

  late final TextEditingController
      _telefonoController;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _nombreController =
        TextEditingController(
      text: widget.nombre,
    );

    _telefonoController =
        TextEditingController(
      text: widget.telefono,
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();

    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _dio.put(
        ApiConfig.meEndpoint,
        data: {
          'nombre':
              _nombreController.text.trim(),
          'telefono':
              _telefonoController.text.trim(),
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
      });

      String mensaje =
          'No fue posible actualizar el perfil.';

      final data =
          error.response?.data;

      if (data is Map) {
        final mensajeServidor =
            data['mensaje'];

        if (mensajeServidor != null &&
            mensajeServidor
                .toString()
                .trim()
                .isNotEmpty) {
          mensaje =
              mensajeServidor.toString();
        }

        final campos = data['campos'];

        if (campos is List &&
            campos.isNotEmpty &&
            campos.first is Map) {
          final primerError =
              campos.first as Map;

          final mensajeCampo =
              primerError['mensaje'];

          if (mensajeCampo != null) {
            mensaje =
                mensajeCampo.toString();
          }
        }
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(mensaje),
          ),
        );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Ocurrió un error al actualizar el perfil.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Editar perfil',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(
                    18,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información personal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              Color(
                            0xFF263238,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      const Text(
                        'Actualiza los datos principales de tu cuenta.',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Color(
                            0xFF78909C,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      TextFormField(
                        controller:
                            _nombreController,
                        textCapitalization:
                            TextCapitalization
                                .words,
                        decoration:
                            _decoracionCampo(
                          label: 'Nombre',
                          icono: Icons
                              .person_outline_rounded,
                        ),
                        validator: (valor) {
                          final texto =
                              valor
                                  ?.trim() ??
                              '';

                          if (texto.isEmpty) {
                            return 'Ingresa tu nombre.';
                          }

                          if (texto.length <
                              2) {
                            return 'El nombre debe tener al menos 2 caracteres.';
                          }

                          if (texto.length >
                              100) {
                            return 'El nombre no puede superar 100 caracteres.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        initialValue:
                            widget.email,
                        enabled: false,
                        decoration:
                            _decoracionCampo(
                          label:
                              'Correo electrónico',
                          icono: Icons
                              .email_outlined,
                        ).copyWith(
                          helperText:
                              'El correo no se puede modificar desde aquí.',
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        controller:
                            _telefonoController,
                        keyboardType:
                            TextInputType.phone,
                        decoration:
                            _decoracionCampo(
                          label: 'Teléfono',
                          icono: Icons
                              .phone_outlined,
                          hint:
                              'Ej. 0991234567',
                        ),
                        validator: (valor) {
                          final texto =
                              valor
                                  ?.trim() ??
                              '';

                          if (texto.length >
                              20) {
                            return 'El teléfono no puede superar 20 caracteres.';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child:
                      FilledButton.icon(
                    onPressed:
                        _guardando
                            ? null
                            : _guardar,
                    style: FilledButton
                        .styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF00796B,
                      ),
                      foregroundColor:
                          Colors.white,
                      disabledBackgroundColor:
                          const Color(
                        0xFF80CBC4,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 15,
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
                    icon: _guardando
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .save_outlined,
                          ),
                    label: Text(
                      _guardando
                          ? 'Guardando...'
                          : 'Guardar cambios',
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Center(
                  child: Text(
                    'Tu correo electrónico se mantiene protegido y no se modifica.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Color(
                        0xFF90A4AE,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        color:
            const Color(0xFF00796B),
      ),
      filled: true,
      fillColor:
          const Color(0xFFF8FAFA),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Color(0xFFCFD8DC),
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Color(0xFFCFD8DC),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Color(0xFF00796B),
          width: 1.5,
        ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../data/local/pet_local_data_source.dart';
import '../data/remote/pet_remote_data_source.dart';
import '../models/pet.dart';

class PetRepository {
  PetRepository({
    PetLocalDataSource? localDataSource,
    PetRemoteDataSource? remoteDataSource,
    Connectivity? connectivity,
  })  : _localDataSource =
            localDataSource ?? PetLocalDataSource(),
        _remoteDataSource =
            remoteDataSource ?? PetRemoteDataSource(),
        _connectivity =
            connectivity ?? Connectivity();

  final PetLocalDataSource _localDataSource;
  final PetRemoteDataSource _remoteDataSource;
  final Connectivity _connectivity;

  final Uuid _uuid = const Uuid();

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  bool _sincronizando = false;

  static const int _maxIntentos = 5;

  // =========================================================
  // INICIAR ESCUCHA DE CONECTIVIDAD
  // =========================================================

  void iniciarSincronizacionAutomatica() {
    _connectivitySubscription?.cancel();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(
      (resultados) async {
        final hayConexion = resultados.any(
          (resultado) =>
              resultado != ConnectivityResult.none,
        );

        if (hayConexion) {
          await sincronizarPendientes();
        }
      },
    );
  }

  // =========================================================
  // DETENER ESCUCHA DE CONECTIVIDAD
  // =========================================================

  Future<void> detenerSincronizacionAutomatica() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  // =========================================================
  // COMPROBAR CONECTIVIDAD
  // =========================================================

  Future<bool> _hayConexion() async {
    final resultados =
        await _connectivity.checkConnectivity();

    return resultados.any(
      (resultado) =>
          resultado != ConnectivityResult.none,
    );
  }

  // =========================================================
  // OBTENER MASCOTAS
  // =========================================================

  Future<List<Pet>> obtenerMascotas() async {
    final mascotasLocales =
        await _localDataSource.obtenerMascotas();

    final hayConexion = await _hayConexion();

    // ---------------------------------------------------------
    // SIN INTERNET
    // ---------------------------------------------------------

    if (!hayConexion) {
      return mascotasLocales
          .where((pet) => !pet.deleted)
          .toList();
    }

    // ---------------------------------------------------------
    // CON INTERNET
    // ---------------------------------------------------------

    try {
      // Primero intentamos enviar operaciones pendientes.
      await sincronizarPendientes();

      final mascotasRemotas =
          await _remoteDataSource.obtenerMascotas();

      final mascotasLocalesActualizadas =
          await _localDataSource.obtenerMascotas();

      final resultado =
          <String, Pet>{};

      // -------------------------------------------------------
      // GUARDAR DATOS REMOTOS
      // -------------------------------------------------------

      for (final petRemota in mascotasRemotas) {
        final local =
            _buscarMascotaPorId(
          mascotasLocalesActualizadas,
          petRemota.id,
        );

        // Si existe una versión local pendiente,
        // respetamos el cambio local.
        if (local != null &&
            local.syncStatus != 'synced') {
          resultado[local.id] = local;
          continue;
        }

        final sincronizada =
            petRemota.copyWith(
          syncStatus: 'synced',
          deleted: false,
        );

        await _localDataSource.guardarMascota(
          sincronizada,
        );

        resultado[sincronizada.id] = sincronizada;
      }

      // -------------------------------------------------------
      // CONSERVAR CAMBIOS LOCALES PENDIENTES
      // -------------------------------------------------------

      for (final local
          in mascotasLocalesActualizadas) {
        if (local.syncStatus != 'synced') {
          resultado[local.id] = local;
        }
      }

      return resultado.values
          .where((pet) => !pet.deleted)
          .toList()
        ..sort(
          (a, b) => a.nombre.compareTo(b.nombre),
        );
    } on DioException {
      // Si falla la comunicación con el servidor,
      // utilizamos los datos locales.
      return mascotasLocales
          .where((pet) => !pet.deleted)
          .toList();
    } catch (_) {
      return mascotasLocales
          .where((pet) => !pet.deleted)
          .toList();
    }
  }

  // =========================================================
  // CREAR MASCOTA
  // =========================================================

  Future<Pet> crearMascota(Pet pet) async {
    final petPendiente = pet.copyWith(
      syncStatus: 'pending',
      deleted: false,
      updatedAt: DateTime.now(),
    );

    // ---------------------------------------------------------
    // GUARDAR PRIMERO EN SQLITE
    // ---------------------------------------------------------

    await _localDataSource.guardarMascota(
      petPendiente,
    );

    // ---------------------------------------------------------
    // CREAR OPERACIÓN PENDIENTE
    // ---------------------------------------------------------

    await _agregarOperacionCrear(
      petPendiente,
    );

    // ---------------------------------------------------------
    // SI HAY INTERNET, INTENTAR SINCRONIZAR
    // ---------------------------------------------------------

    if (await _hayConexion()) {
      await sincronizarPendientes();
    }

    // ---------------------------------------------------------
    // DEVOLVER LA VERSIÓN ACTUAL LOCAL
    // ---------------------------------------------------------

    final mascotas =
        await _localDataSource.obtenerMascotas();

    return _buscarMascotaPorId(
          mascotas,
          petPendiente.id,
        ) ??
        petPendiente;
  }

  // =========================================================
  // ELIMINAR MASCOTA
  // =========================================================

  Future<void> eliminarMascota(
    String id,
  ) async {
    // ---------------------------------------------------------
    // MARCAR COMO ELIMINADA LOCALMENTE
    // ---------------------------------------------------------

    await _localDataSource.eliminarMascota(
      id,
    );

    // ---------------------------------------------------------
    // AGREGAR DELETE A LA COLA
    // ---------------------------------------------------------

    await _agregarOperacionEliminar(
      id,
    );

    // ---------------------------------------------------------
    // SI HAY INTERNET, INTENTAR SINCRONIZAR
    // ---------------------------------------------------------

    if (await _hayConexion()) {
      await sincronizarPendientes();
    }
  }

  // =========================================================
  // AGREGAR CREATE A LA COLA
  // =========================================================

  Future<void> _agregarOperacionCrear(
    Pet pet,
  ) async {
    final operacion = {
      'operation_id': _uuid.v4(),
      'entity': 'pets',
      'entity_id': pet.id,
      'operation': 'CREATE',
      'payload': jsonEncode({
        'id': pet.id,
        'nombre': pet.nombre,
        'especie': pet.especie,
        'raza': pet.raza,
        'edad': pet.edad,
      }),
      'created_at':
          DateTime.now().toIso8601String(),
      'attempts': 0,
      'next_attempt_at': null,
      'status': 'pending',
    };

    await _localDataSource
        .agregarOperacionPendiente(
      operacion,
    );
  }

  // =========================================================
  // AGREGAR DELETE A LA COLA
  // =========================================================

  Future<void> _agregarOperacionEliminar(
    String id,
  ) async {
    final operacion = {
      'operation_id': _uuid.v4(),
      'entity': 'pets',
      'entity_id': id,
      'operation': 'DELETE',
      'payload': jsonEncode({
        'id': id,
      }),
      'created_at':
          DateTime.now().toIso8601String(),
      'attempts': 0,
      'next_attempt_at': null,
      'status': 'pending',
    };

    await _localDataSource
        .agregarOperacionPendiente(
      operacion,
    );
  }

  // =========================================================
  // SINCRONIZAR OPERACIONES PENDIENTES
  // =========================================================

  Future<void> sincronizarPendientes() async {
    if (_sincronizando) {
      return;
    }

    if (!await _hayConexion()) {
      return;
    }

    _sincronizando = true;

    try {
      final operaciones =
          await _localDataSource
              .obtenerOperacionesPendientes();

      for (final operacion in operaciones) {
        if (!_puedeIntentarseAhora(operacion)) {
          continue;
        }

        final operationId =
            operacion['operation_id'] as String;

        final operation =
            operacion['operation'] as String;

        final attempts =
            (operacion['attempts'] as int?) ?? 0;

        try {
          // ---------------------------------------------------
          // CREATE
          // ---------------------------------------------------

          if (operation == 'CREATE') {
            await _sincronizarCreate(
              operacion,
            );
          }

          // ---------------------------------------------------
          // DELETE
          // ---------------------------------------------------

          else if (operation == 'DELETE') {
            await _sincronizarDelete(
              operacion,
            );
          }

          // ---------------------------------------------------
          // OPERACIÓN NO SOPORTADA
          // ---------------------------------------------------

          else {
            await _localDataSource
                .actualizarOperacionPendiente(
              operationId,
              {
                'status': 'failed',
                'next_attempt_at': null,
              },
            );

            continue;
          }

          // ---------------------------------------------------
          // OPERACIÓN COMPLETADA
          // ---------------------------------------------------

          await _localDataSource
              .actualizarOperacionPendiente(
            operationId,
            {
              'status': 'synced',
              'next_attempt_at': null,
            },
          );
        } catch (_) {
          // ---------------------------------------------------
          // ERROR EN LA OPERACIÓN
          // ---------------------------------------------------

          final nuevosIntentos =
              attempts + 1;

          if (nuevosIntentos >= _maxIntentos) {
            await _localDataSource
                .actualizarOperacionPendiente(
              operationId,
              {
                'attempts': nuevosIntentos,
                'status': 'failed',
                'next_attempt_at': null,
              },
            );
          } else {
            final segundosEspera =
                _calcularBackoff(
              nuevosIntentos,
            );

            final siguienteIntento =
                DateTime.now().add(
              Duration(
                seconds: segundosEspera,
              ),
            );

            await _localDataSource
                .actualizarOperacionPendiente(
              operationId,
              {
                'attempts': nuevosIntentos,
                'status': 'pending',
                'next_attempt_at':
                    siguienteIntento
                        .toIso8601String(),
              },
            );
          }
        }
      }
    } finally {
      _sincronizando = false;
    }
  }

  // =========================================================
  // SINCRONIZAR CREATE
  // =========================================================

  Future<void> _sincronizarCreate(
    Map<String, dynamic> operacion,
  ) async {
    final payload =
        jsonDecode(
      operacion['payload'] as String,
    );

    if (payload is! Map) {
      throw Exception(
        'Payload CREATE inválido.',
      );
    }

    final pet =
        Pet(
      id: payload['id'] as String,
      nombre: payload['nombre'] as String,
      especie: payload['especie'] as String,
      raza: payload['raza'] as String,
      edad: payload['edad'] as int,
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
      deleted: false,
    );

    // ---------------------------------------------------------
    // EL BACKEND UTILIZA EL UUID DEL CLIENTE
    // PARA HACER EL CREATE IDEMPOTENTE.
    // ---------------------------------------------------------

    final mascotaRemota =
        await _remoteDataSource.crearMascota(
      pet,
    );

    final mascotaSincronizada =
        mascotaRemota.copyWith(
      syncStatus: 'synced',
      deleted: false,
    );

    await _localDataSource
        .guardarMascota(
      mascotaSincronizada,
    );
  }

  // =========================================================
  // SINCRONIZAR DELETE
  // =========================================================

  Future<void> _sincronizarDelete(
    Map<String, dynamic> operacion,
  ) async {
    final payload =
        jsonDecode(
      operacion['payload'] as String,
    );

    if (payload is! Map) {
      throw Exception(
        'Payload DELETE inválido.',
      );
    }

    final id = payload['id'] as String;

    // DELETE es idempotente:
    // repetirlo no debe crear información duplicada.
    await _remoteDataSource.eliminarMascota(
      id,
    );
  }

  // =========================================================
  // COMPROBAR SI PUEDE INTENTARSE
  // =========================================================

  bool _puedeIntentarseAhora(
    Map<String, dynamic> operacion,
  ) {
    final status =
        operacion['status'] as String?;

    if (status != 'pending') {
      return false;
    }

    final nextAttemptAt =
        operacion['next_attempt_at']
            as String?;

    if (nextAttemptAt == null ||
        nextAttemptAt.isEmpty) {
      return true;
    }

    final fechaSiguiente =
        DateTime.tryParse(
      nextAttemptAt,
    );

    if (fechaSiguiente == null) {
      return true;
    }

    return !DateTime.now()
        .isBefore(fechaSiguiente);
  }

  // =========================================================
  // BACKOFF EXPONENCIAL
  // =========================================================

  int _calcularBackoff(
    int attempts,
  ) {
    const maxSeconds = 60;

    final seconds =
        2 * (1 << (attempts - 1));

    if (seconds > maxSeconds) {
      return maxSeconds;
    }

    return seconds;
  }

  // =========================================================
  // BUSCAR MASCOTA POR ID
  // =========================================================

  Pet? _buscarMascotaPorId(
    List<Pet> mascotas,
    String id,
  ) {
    for (final pet in mascotas) {
      if (pet.id == id) {
        return pet;
      }
    }

    return null;
  }

  // =========================================================
  // OBTENER OPERACIONES PENDIENTES
  // =========================================================

  Future<List<Map<String, dynamic>>>
      obtenerOperacionesPendientes() async {
    return _localDataSource
        .obtenerOperacionesPendientes();
  }

  // =========================================================
  // ACTUALIZAR OPERACIÓN
  // =========================================================

  Future<void> actualizarOperacionPendiente(
    String operationId,
    Map<String, dynamic> values,
  ) async {
    await _localDataSource
        .actualizarOperacionPendiente(
      operationId,
      values,
    );
  }
}
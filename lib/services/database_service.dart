import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/pet.dart';

class DatabaseService {
  DatabaseService._privateConstructor();

  static final DatabaseService instance =
      DatabaseService._privateConstructor();

  Database? _database;

  final Uuid _uuid = const Uuid();

  // =========================================================
  // OBTENER BASE DE DATOS
  // =========================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  // =========================================================
  // INICIALIZAR SQLITE
  // =========================================================

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'petcare.db',
    );

    print(
      'PETCARE DIAGNOSTICO: RUTA SQLITE = $path',
    );

    return await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // =========================================================
  // CREAR TABLAS
  // =========================================================

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    print(
      'PETCARE DIAGNOSTICO: CREANDO BASE DE DATOS',
    );

    // =======================================================
    // TABLA DE MASCOTAS
    // =======================================================

    await db.execute('''
      CREATE TABLE pets (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        especie TEXT NOT NULL,
        raza TEXT NOT NULL,
        edad INTEGER NOT NULL,
        peso REAL,
        alergias TEXT,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // =======================================================
    // TABLA DE OPERACIONES PENDIENTES
    // =======================================================

    await db.execute('''
      CREATE TABLE pending_operations (
        operation_id TEXT PRIMARY KEY,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        next_attempt_at TEXT,
        status TEXT NOT NULL
      )
    ''');

    // =======================================================
    // TABLA DE USUARIOS
    // =======================================================

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // =======================================================
    // TABLA DE RECORDATORIOS
    // =======================================================

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        titulo TEXT NOT NULL,
        mascota TEXT NOT NULL,
        fecha TEXT NOT NULL,
        tipo TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // =======================================================
    // TABLA DE CITAS VETERINARIAS
    // =======================================================

    await db.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        mascota TEXT NOT NULL,
        veterinario TEXT NOT NULL,
        motivo TEXT NOT NULL,
        fecha TEXT NOT NULL,
        hora TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // =======================================================
    // TABLA DE VETERINARIOS
    // =======================================================

    await db.execute('''
      CREATE TABLE veterinarians (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        especialidad TEXT NOT NULL,
        telefono TEXT NOT NULL,
        clinica TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // =======================================================
    // TABLA DE VACUNAS
    // =======================================================

    await db.execute('''
      CREATE TABLE vaccines (
        id TEXT PRIMARY KEY,
        pet_id TEXT NOT NULL,
        vacuna TEXT NOT NULL,
        fecha_aplicacion TEXT NOT NULL,
        proxima_dosis TEXT,
        veterinario TEXT NOT NULL,
        observaciones TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // =======================================================
    // TABLA DE DESPARASITACIONES
    // =======================================================

    await db.execute('''
      CREATE TABLE dewormings (
        id TEXT PRIMARY KEY,
        pet_id TEXT NOT NULL,
        tipo TEXT NOT NULL,
        fecha_aplicacion TEXT NOT NULL,
        proxima_dosis TEXT,
        veterinario TEXT NOT NULL,
        observaciones TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // =======================================================
    // VETERINARIOS DE DEMOSTRACIÓN
    // =======================================================

    await _insertarVeterinariosIniciales(db);

    print(
      'PETCARE DIAGNOSTICO: TABLAS CREADAS CORRECTAMENTE',
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'VETERINARIOS INICIALES CREADOS',
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'TABLA VACCINES CREADA',
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'TABLA DEWORMINGS CREADA',
    );
  }

  // =========================================================
  // INSERTAR VETERINARIOS INICIALES
  // =========================================================

  Future<void> _insertarVeterinariosIniciales(
    Database db,
  ) async {
    final veterinarios = [
      {
        'id': _uuid.v4(),
        'nombre': 'Dra. Ana Torres',
        'especialidad': 'Medicina veterinaria',
        'telefono': '099 123 4567',
        'clinica': 'Clínica Animal Care',
        'created_at':
            DateTime.now().toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'nombre': 'Dr. Víctor Moscoso',
        'especialidad': 'Medicina veterinaria',
        'telefono': '098 234 5678',
        'clinica': 'Veterinaria Patitas',
        'created_at':
            DateTime.now().toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'nombre': 'Dra. María González',
        'especialidad': 'Dermatología veterinaria',
        'telefono': '097 345 6789',
        'clinica': 'Centro Veterinario Quito',
        'created_at':
            DateTime.now().toIso8601String(),
      },
    ];

    for (final veterinario in veterinarios) {
      await db.insert(
        'veterinarians',
        veterinario,
        conflictAlgorithm:
            ConflictAlgorithm.ignore,
      );
    }
  }

  // =========================================================
  // MIGRACIONES
  // =========================================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    print(
      'PETCARE DIAGNOSTICO: MIGRACION '
      '$oldVersion -> $newVersion',
    );

    // =======================================================
    // VERSION 2
    // Agrega tabla users
    // =======================================================

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          nombre TEXT NOT NULL,
          correo TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          password_salt TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      print(
        'PETCARE DIAGNOSTICO: TABLA USERS '
        'CREADA EN MIGRACION',
      );
    }

    // =======================================================
    // VERSION 3
    // Agrega tabla reminders
    // =======================================================

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE reminders (
          id TEXT PRIMARY KEY,
          titulo TEXT NOT NULL,
          mascota TEXT NOT NULL,
          fecha TEXT NOT NULL,
          tipo TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      print(
        'PETCARE DIAGNOSTICO: TABLA REMINDERS '
        'CREADA EN MIGRACION',
      );
    }

    // =======================================================
    // VERSION 4
    // Agrega tabla appointments
    // =======================================================

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE appointments (
          id TEXT PRIMARY KEY,
          mascota TEXT NOT NULL,
          veterinario TEXT NOT NULL,
          motivo TEXT NOT NULL,
          fecha TEXT NOT NULL,
          hora TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      print(
        'PETCARE DIAGNOSTICO: TABLA APPOINTMENTS '
        'CREADA EN MIGRACION',
      );
    }

    // =======================================================
    // VERSION 5
    // Agrega tabla veterinarians
    // =======================================================

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE veterinarians (
          id TEXT PRIMARY KEY,
          nombre TEXT NOT NULL,
          especialidad TEXT NOT NULL,
          telefono TEXT NOT NULL,
          clinica TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await _insertarVeterinariosIniciales(db);

      print(
        'PETCARE DIAGNOSTICO: TABLA VETERINARIANS '
        'CREADA EN MIGRACION',
      );

      print(
        'PETCARE DIAGNOSTICO: '
        'VETERINARIOS INICIALES CREADOS',
      );
    }

    // =======================================================
    // VERSION 6
    // Agrega tabla vaccines
    // =======================================================

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE vaccines (
          id TEXT PRIMARY KEY,
          pet_id TEXT NOT NULL,
          vacuna TEXT NOT NULL,
          fecha_aplicacion TEXT NOT NULL,
          proxima_dosis TEXT,
          veterinario TEXT NOT NULL,
          observaciones TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      print(
        'PETCARE DIAGNOSTICO: TABLA VACCINES '
        'CREADA EN MIGRACION',
      );
    }

    // =======================================================
    // VERSION 7
    // Agrega tabla dewormings
    // =======================================================

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE dewormings (
          id TEXT PRIMARY KEY,
          pet_id TEXT NOT NULL,
          tipo TEXT NOT NULL,
          fecha_aplicacion TEXT NOT NULL,
          proxima_dosis TEXT,
          veterinario TEXT NOT NULL,
          observaciones TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      print(
        'PETCARE DIAGNOSTICO: TABLA DEWORMINGS '
        'CREADA EN MIGRACION',
      );
    }    
    
    // =======================================================
    // VERSION 8
    // Agrega peso y alergias a mascotas
    // =======================================================

    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE pets ADD COLUMN peso REAL',
      );

      await db.execute(
        'ALTER TABLE pets ADD COLUMN alergias TEXT',
      );

      print(
        'PETCARE DIAGNOSTICO: '
        'COLUMNAS PESO Y ALERGIAS AGREGADAS A PETS',
      );
    }
  }

  // =========================================================
  // GENERAR HASH DE CONTRASEÑA
  // =========================================================

  String _generarHashPassword(
    String password,
    String salt,
  ) {
    final bytes = utf8.encode(
      '$salt:$password',
    );

    return sha256.convert(bytes).toString();
  }

  // =========================================================
  // REGISTRAR USUARIO
  // =========================================================

  Future<bool> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    final db = await database;

    final correoNormalizado =
        correo.trim().toLowerCase();

    print(
      'PETCARE DIAGNOSTICO: REGISTRANDO USUARIO '
      '$correoNormalizado',
    );

    final usuariosExistentes = await db.query(
      'users',
      where: 'correo = ?',
      whereArgs: [correoNormalizado],
      limit: 1,
    );

    print(
      'PETCARE DIAGNOSTICO: USUARIOS CON ESE CORREO = '
      '${usuariosExistentes.length}',
    );

    if (usuariosExistentes.isNotEmpty) {
      return false;
    }

    final salt = _uuid.v4();

    final passwordHash =
        _generarHashPassword(
      password,
      salt,
    );

    await db.insert(
      'users',
      {
        'id': _uuid.v4(),
        'nombre': nombre.trim(),
        'correo': correoNormalizado,
        'password_hash': passwordHash,
        'password_salt': salt,
        'created_at':
            DateTime.now().toIso8601String(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.abort,
    );

    print(
      'PETCARE DIAGNOSTICO: USUARIO '
      'GUARDADO CORRECTAMENTE',
    );

    await diagnosticarUsuarios();

    return true;
  }

  // =========================================================
  // BUSCAR USUARIO POR CORREO
  // =========================================================

  Future<Map<String, dynamic>?>
      obtenerUsuarioPorCorreo(
    String correo,
  ) async {
    final db = await database;

    final correoNormalizado =
        correo.trim().toLowerCase();

    final resultados = await db.query(
      'users',
      where: 'correo = ?',
      whereArgs: [correoNormalizado],
      limit: 1,
    );

    print(
      'PETCARE DIAGNOSTICO: BUSQUEDA DE '
      '$correoNormalizado -> '
      '${resultados.length} RESULTADO(S)',
    );

    if (resultados.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(
      resultados.first,
    );
  }

  // =========================================================
  // VALIDAR CREDENCIALES
  // =========================================================

  Future<Map<String, dynamic>?>
      validarCredenciales({
    required String correo,
    required String password,
  }) async {
    print(
      'PETCARE DIAGNOSTICO: VALIDANDO LOGIN PARA '
      '$correo',
    );

    await diagnosticarUsuarios();

    final usuario =
        await obtenerUsuarioPorCorreo(
      correo,
    );

    if (usuario == null) {
      print(
        'PETCARE DIAGNOSTICO: USUARIO NO EXISTE',
      );

      return null;
    }

    final salt =
        usuario['password_salt'] as String;

    final passwordHashGuardado =
        usuario['password_hash'] as String;

    final passwordHashIngresado =
        _generarHashPassword(
      password,
      salt,
    );

    if (passwordHashIngresado !=
        passwordHashGuardado) {
      print(
        'PETCARE DIAGNOSTICO: '
        'CONTRASEÑA INCORRECTA',
      );

      return null;
    }

    print(
      'PETCARE DIAGNOSTICO: '
      'CREDENCIALES CORRECTAS',
    );

    return usuario;
  }

  // =========================================================
  // INSERTAR MASCOTA
  // =========================================================

  Future<void> insertarMascota(
    Pet pet,
  ) async {
    final db = await database;

    await db.insert(
      'pets',
      pet.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  // =========================================================
  // OBTENER MASCOTAS
  // =========================================================

  Future<List<Pet>> obtenerMascotas() async {
    final db = await database;

    final maps = await db.query(
      'pets',
      where: 'deleted = ?',
      whereArgs: [0],
      orderBy: 'nombre ASC',
    );

    return maps
        .map(
          (map) => Pet.fromMap(
            Map<String, dynamic>.from(map),
          ),
        )
        .toList();
  }

  // =========================================================
  // ACTUALIZAR MASCOTA
  // =========================================================

  Future<void> actualizarMascota(
    Pet pet,
  ) async {
    final db = await database;

    await db.update(
      'pets',
      pet.toMap(),
      where: 'id = ?',
      whereArgs: [pet.id],
    );
  }

    // =========================================================
  // ACTUALIZAR INFORMACIÓN DE MASCOTA
  // Peso y alergias
  // =========================================================

  Future<void> actualizarInformacionMascota({
    required String id,
    required double? peso,
    required String alergias,
  }) async {
    final db = await database;

    await db.update(
      'pets',
      {
        'peso': peso,
        'alergias': alergias.trim(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'INFORMACION DE MASCOTA ACTUALIZADA = $id',
    );
  }

  // =========================================================
  // ELIMINAR MASCOTA
  // =========================================================

  Future<void> eliminarMascota(
    String id,
  ) async {
    final db = await database;

    await db.update(
      'pets',
      {
        'deleted': 1,
        'sync_status': 'pending',
        'updated_at':
            DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================================================
  // INSERTAR OPERACIÓN PENDIENTE
  // =========================================================

  Future<void> insertarOperacionPendiente(
    Map<String, dynamic> operation,
  ) async {
    final db = await database;

    await db.insert(
      'pending_operations',
      Map<String, dynamic>.from(operation),
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  // =========================================================
  // OBTENER OPERACIONES PENDIENTES
  // =========================================================

  Future<List<Map<String, dynamic>>>
      obtenerOperacionesPendientes() async {
    final db = await database;

    final resultados = await db.query(
      'pending_operations',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );

    return resultados
        .map(
          (operation) =>
              Map<String, dynamic>.from(
            operation,
          ),
        )
        .toList();
  }

  // =========================================================
  // ACTUALIZAR OPERACIÓN PENDIENTE
  // =========================================================

  Future<void> actualizarOperacionPendiente(
    String operationId,
    Map<String, dynamic> values,
  ) async {
    final db = await database;

    await db.update(
      'pending_operations',
      Map<String, dynamic>.from(values),
      where: 'operation_id = ?',
      whereArgs: [operationId],
    );
  }

  // =========================================================
  // INSERTAR RECORDATORIO
  // =========================================================

  Future<void> insertarRecordatorio({
    required String titulo,
    required String mascota,
    required String fecha,
    required String tipo,
  }) async {
    final db = await database;

    await db.insert(
      'reminders',
      {
        'id': _uuid.v4(),
        'titulo': titulo.trim(),
        'mascota': mascota.trim(),
        'fecha': fecha,
        'tipo': tipo,
        'created_at':
            DateTime.now().toIso8601String(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.abort,
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'RECORDATORIO GUARDADO',
    );
  }

  // =========================================================
  // OBTENER RECORDATORIOS
  // =========================================================

  Future<List<Map<String, dynamic>>>
      obtenerRecordatorios() async {
    try {
      final db = await database;

      final resultados = await db.query(
        'reminders',
        orderBy: 'created_at ASC',
      );

      final recordatorios =
          resultados
              .map(
                (recordatorio) =>
                    Map<String, dynamic>.from(
                  recordatorio,
                ),
              )
              .toList();

      print(
        'PETCARE DIAGNOSTICO: '
        'RECORDATORIOS CARGADOS = '
        '${recordatorios.length}',
      );

      return recordatorios;
    } catch (e) {
      print(
        'PETCARE DIAGNOSTICO: '
        'ERROR AL OBTENER RECORDATORIOS: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // ELIMINAR RECORDATORIO
  // =========================================================

  Future<void> eliminarRecordatorio(
    String id,
  ) async {
    final db = await database;

    await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'RECORDATORIO ELIMINADO = $id',
    );
  }

  // =========================================================
  // INSERTAR CITA VETERINARIA
  // =========================================================

    // =========================================================
  // INSERTAR CITA VETERINARIA
  // =========================================================

  Future<void> insertarCitaVeterinaria({
    required String mascota,
    required String veterinario,
    required String motivo,
    required String fecha,
    required String hora,
  }) async {
    final db = await database;

    await db.insert(
      'appointments',
      {
        'id': _uuid.v4(),
        'mascota': mascota.trim(),
        'veterinario': veterinario.trim(),
        'motivo': motivo.trim(),
        'fecha': fecha,
        'hora': hora,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'CITA VETERINARIA GUARDADA',
    );
  }

  // =========================================================
  // OBTENER CITAS VETERINARIAS
  // =========================================================

  Future<List<Map<String, dynamic>>>
      obtenerCitasVeterinarias() async {
    try {
      final db = await database;

      final resultados = await db.query(
        'appointments',
        orderBy: 'fecha ASC, hora ASC',
      );

      final citas = resultados
          .map(
            (cita) => Map<String, dynamic>.from(
              cita,
            ),
          )
          .toList();

      print(
        'PETCARE DIAGNOSTICO: '
        'CITAS VETERINARIAS CARGADAS = '
        '${citas.length}',
      );

      return citas;
    } catch (e) {
      print(
        'PETCARE DIAGNOSTICO: '
        'ERROR AL OBTENER CITAS: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // ACTUALIZAR CITA VETERINARIA
  // =========================================================

  Future<void> actualizarCitaVeterinaria({
    required String id,
    required String mascota,
    required String veterinario,
    required String motivo,
    required String fecha,
    required String hora,
  }) async {
    final db = await database;

    await db.update(
      'appointments',
      {
        'mascota': mascota.trim(),
        'veterinario': veterinario.trim(),
        'motivo': motivo.trim(),
        'fecha': fecha,
        'hora': hora,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'CITA VETERINARIA ACTUALIZADA = $id',
    );
  }

  // =========================================================
  // ELIMINAR CITA VETERINARIA
  // =========================================================

  Future<void> eliminarCitaVeterinaria(
    String id,
  ) async {
    final db = await database;

    await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'CITA VETERINARIA ELIMINADA = $id',
    );
  }

  // =========================================================
  // INSERTAR VETERINARIO
  // =========================================================

  Future<void> insertarVeterinario({
    required String nombre,
    required String especialidad,
    required String telefono,
    required String clinica,
  }) async {
    final db = await database;

    await db.insert(
      'veterinarians',
      {
        'id': _uuid.v4(),
        'nombre': nombre.trim(),
        'especialidad': especialidad.trim(),
        'telefono': telefono.trim(),
        'clinica': clinica.trim(),
        'created_at':
            DateTime.now().toIso8601String(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.abort,
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'VETERINARIO GUARDADO',
    );
  }

  // =========================================================
  // OBTENER VETERINARIOS
  // =========================================================

  Future<List<Map<String, dynamic>>>
      obtenerVeterinarios() async {
    try {
      final db = await database;

      final resultados = await db.query(
        'veterinarians',
        orderBy: 'nombre ASC',
      );

      final veterinarios =
          resultados
              .map(
                (veterinario) =>
                    Map<String, dynamic>.from(
                  veterinario,
                ),
              )
              .toList();

      print(
        'PETCARE DIAGNOSTICO: '
        'VETERINARIOS CARGADOS = '
        '${veterinarios.length}',
      );

      return veterinarios;
    } catch (e) {
      print(
        'PETCARE DIAGNOSTICO: '
        'ERROR AL OBTENER VETERINARIOS: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // ACTUALIZAR VETERINARIO
  // =========================================================

  Future<void> actualizarVeterinario({
    required String id,
    required String nombre,
    required String especialidad,
    required String telefono,
    required String clinica,
  }) async {
    final db = await database;

    await db.update(
      'veterinarians',
      {
        'nombre': nombre.trim(),
        'especialidad': especialidad.trim(),
        'telefono': telefono.trim(),
        'clinica': clinica.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'VETERINARIO ACTUALIZADO = $id',
    );
  }

  // =========================================================
  // ELIMINAR VETERINARIO
  // =========================================================

  Future<void> eliminarVeterinario(
    String id,
  ) async {
    final db = await database;

    await db.delete(
      'veterinarians',
      where: 'id = ?',
      whereArgs: [id],
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'VETERINARIO ELIMINADO = $id',
    );
  }

  // =========================================================
  // INSERTAR VACUNA
  // =========================================================

  Future<void> insertarVacuna({
    required String petId,
    required String vacuna,
    required String fechaAplicacion,
    String? proximaDosis,
    required String veterinario,
    required String observaciones,
  }) async {
    final db = await database;

    await db.insert(
      'vaccines',
      {
        'id': _uuid.v4(),
        'pet_id': petId,
        'vacuna': vacuna.trim(),
        'fecha_aplicacion': fechaAplicacion,
        'proxima_dosis': proximaDosis,
        'veterinario': veterinario.trim(),
        'observaciones': observaciones.trim(),
        'created_at':
            DateTime.now().toIso8601String(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.abort,
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'VACUNA GUARDADA PARA MASCOTA = $petId',
    );
  }

  // =========================================================
  // OBTENER VACUNAS DE UNA MASCOTA
  // =========================================================

  Future<List<Map<String, dynamic>>>
      obtenerVacunasPorMascota(
    String petId,
  ) async {
    try {
      final db = await database;

      final resultados = await db.query(
        'vaccines',
        where: 'pet_id = ?',
        whereArgs: [petId],
        orderBy:
            'fecha_aplicacion DESC, created_at DESC',
      );

      final vacunas =
          resultados
              .map(
                (vacuna) =>
                    Map<String, dynamic>.from(
                  vacuna,
                ),
              )
              .toList();

      print(
        'PETCARE DIAGNOSTICO: '
        'VACUNAS DE MASCOTA $petId = '
        '${vacunas.length}',
      );

      return vacunas;
    } catch (e) {
      print(
        'PETCARE DIAGNOSTICO: '
        'ERROR AL OBTENER VACUNAS: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // ACTUALIZAR VACUNA
  // =========================================================

  Future<void> actualizarVacuna({
    required String id,
    required String petId,
    required String vacuna,
    required String fechaAplicacion,
    String? proximaDosis,
    required String veterinario,
    required String observaciones,
  }) async {
    final db = await database;

    await db.update(
      'vaccines',
      {
        'pet_id': petId,
        'vacuna': vacuna.trim(),
        'fecha_aplicacion': fechaAplicacion,
        'proxima_dosis': proximaDosis,
        'veterinario': veterinario.trim(),
        'observaciones': observaciones.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'VACUNA ACTUALIZADA = $id',
    );
  }

  // =========================================================
  // ELIMINAR VACUNA
  // =========================================================

  Future<void> eliminarVacuna(
    String id,
  ) async {
    final db = await database;

    await db.delete(
      'vaccines',
      where: 'id = ?',
      whereArgs: [id],
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'VACUNA ELIMINADA = $id',
    );
  }

  // =========================================================
  // OBTENER TODAS LAS VACUNAS
  // =========================================================

  Future<List<Map<String, dynamic>>>
      obtenerTodasLasVacunas() async {
    try {
      final db = await database;

      final resultados = await db.query(
        'vaccines',
        orderBy:
            'fecha_aplicacion DESC, created_at DESC',
      );

      return resultados
          .map(
            (vacuna) =>
                Map<String, dynamic>.from(
              vacuna,
            ),
          )
          .toList();
    } catch (e) {
      print(
        'PETCARE DIAGNOSTICO: '
        'ERROR AL OBTENER TODAS LAS VACUNAS: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // INSERTAR DESPARASITACIÓN
  // =========================================================

  Future<void> insertarDesparasitacion({
    required String petId,
    required String tipo,
    required String fechaAplicacion,
    String? proximaDosis,
    required String veterinario,
    required String observaciones,
  }) async {
    final db = await database;

    await db.insert(
      'dewormings',
      {
        'id': _uuid.v4(),
        'pet_id': petId,
        'tipo': tipo.trim(),
        'fecha_aplicacion': fechaAplicacion,
        'proxima_dosis': proximaDosis,
        'veterinario': veterinario.trim(),
        'observaciones': observaciones.trim(),
        'created_at':
            DateTime.now().toIso8601String(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.abort,
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'DESPARASITACION GUARDADA PARA MASCOTA = $petId',
    );
  }

  // =========================================================
  // OBTENER DESPARASITACIONES DE UNA MASCOTA
  // =========================================================

  Future<List<Map<String, dynamic>>>
      obtenerDesparasitacionesPorMascota(
    String petId,
  ) async {
    try {
      final db = await database;

      final resultados = await db.query(
        'dewormings',
        where: 'pet_id = ?',
        whereArgs: [petId],
        orderBy:
            'fecha_aplicacion DESC, created_at DESC',
      );

      final desparasitaciones =
          resultados
              .map(
                (desparasitacion) =>
                    Map<String, dynamic>.from(
                  desparasitacion,
                ),
              )
              .toList();

      print(
        'PETCARE DIAGNOSTICO: '
        'DESPARASITACIONES DE MASCOTA $petId = '
        '${desparasitaciones.length}',
      );

      return desparasitaciones;
    } catch (e) {
      print(
        'PETCARE DIAGNOSTICO: '
        'ERROR AL OBTENER DESPARASITACIONES: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // ACTUALIZAR DESPARASITACIÓN
  // =========================================================

  Future<void> actualizarDesparasitacion({
    required String id,
    required String petId,
    required String tipo,
    required String fechaAplicacion,
    String? proximaDosis,
    required String veterinario,
    required String observaciones,
  }) async {
    final db = await database;

    await db.update(
      'dewormings',
      {
        'pet_id': petId,
        'tipo': tipo.trim(),
        'fecha_aplicacion': fechaAplicacion,
        'proxima_dosis': proximaDosis,
        'veterinario': veterinario.trim(),
        'observaciones': observaciones.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'DESPARASITACION ACTUALIZADA = $id',
    );
  }

  // =========================================================
  // ELIMINAR DESPARASITACIÓN
  // =========================================================

  Future<void> eliminarDesparasitacion(
    String id,
  ) async {
    final db = await database;

    await db.delete(
      'dewormings',
      where: 'id = ?',
      whereArgs: [id],
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'DESPARASITACION ELIMINADA = $id',
    );
  }

  // =========================================================
  // OBTENER TODAS LAS DESPARASITACIONES
  // =========================================================

  Future<List<Map<String, dynamic>>>
      obtenerTodasLasDesparasitaciones() async {
    try {
      final db = await database;

      final resultados = await db.query(
        'dewormings',
        orderBy:
            'fecha_aplicacion DESC, created_at DESC',
      );

      return resultados
          .map(
            (desparasitacion) =>
                Map<String, dynamic>.from(
              desparasitacion,
            ),
          )
          .toList();
    } catch (e) {
      print(
        'PETCARE DIAGNOSTICO: '
        'ERROR AL OBTENER TODAS LAS DESPARASITACIONES: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // DIAGNÓSTICO DE VACUNAS
  // =========================================================

  Future<void> diagnosticarVacunas() async {
    final db = await database;

    final resultado = await db.rawQuery(
      'SELECT COUNT(*) AS cantidad FROM vaccines',
    );

    final cantidad =
        resultado.first['cantidad'];

    print(
      'PETCARE DIAGNOSTICO: '
      'VACUNAS EN SQLITE = $cantidad',
    );
  }

  // =========================================================
  // DIAGNÓSTICO DE DESPARASITACIONES
  // =========================================================

  Future<void> diagnosticarDesparasitaciones() async {
    final db = await database;

    final resultado = await db.rawQuery(
      'SELECT COUNT(*) AS cantidad FROM dewormings',
    );

    final cantidad =
        resultado.first['cantidad'];

    print(
      'PETCARE DIAGNOSTICO: '
      'DESPARASITACIONES EN SQLITE = $cantidad',
    );
  }

  // =========================================================
  // DIAGNÓSTICO DE USUARIOS
  // =========================================================

  Future<void> diagnosticarUsuarios() async {
    final db = await database;

    final resultado = await db.rawQuery(
      'SELECT COUNT(*) AS cantidad FROM users',
    );

    final cantidad =
        resultado.first['cantidad'];

    print(
      'PETCARE DIAGNOSTICO: '
      'USUARIOS EN SQLITE = $cantidad',
    );
  }

  // =========================================================
  // DIAGNÓSTICO COMPLETO DE LA BASE
  // =========================================================

  Future<void> diagnosticarBaseDatos() async {
    final db = await database;

    final usuarios = await db.rawQuery(
      'SELECT COUNT(*) AS cantidad FROM users',
    );

    final mascotas = await db.rawQuery(
      'SELECT COUNT(*) AS cantidad FROM pets',
    );

    final operaciones = await db.rawQuery(
      'SELECT COUNT(*) AS cantidad '
      'FROM pending_operations',
    );

    final recordatorios = await db.rawQuery(
      'SELECT COUNT(*) AS cantidad '
      'FROM reminders',
    );

    final citas = await db.rawQuery(
      'SELECT COUNT(*) AS cantidad '
      'FROM appointments',
    );

    final veterinarios = await db.rawQuery(
      'SELECT COUNT(*) AS cantidad '
      'FROM veterinarians',
    );

    final vacunas = await db.rawQuery(
      'SELECT COUNT(*) AS cantidad '
      'FROM vaccines',
    );

    final desparasitaciones = await db.rawQuery(
      'SELECT COUNT(*) AS cantidad '
      'FROM dewormings',
    );

    print(
      '=====================================================',
    );

    print(
      'PETCARE DIAGNOSTICO: ESTADO DE SQLITE',
    );

    print(
      'USUARIOS: ${usuarios.first['cantidad']}',
    );

    print(
      'MASCOTAS: ${mascotas.first['cantidad']}',
    );

    print(
      'OPERACIONES PENDIENTES: '
      '${operaciones.first['cantidad']}',
    );

    print(
      'RECORDATORIOS: '
      '${recordatorios.first['cantidad']}',
    );

    print(
      'CITAS VETERINARIAS: '
      '${citas.first['cantidad']}',
    );

    print(
      'VETERINARIOS: '
      '${veterinarios.first['cantidad']}',
    );

    print(
      'VACUNAS: '
      '${vacunas.first['cantidad']}',
    );

    print(
      'DESPARASITACIONES: '
      '${desparasitaciones.first['cantidad']}',
    );

    print(
      '=====================================================',
    );
  }

  // =========================================================
  // CERRAR BASE DE DATOS
  // =========================================================

  Future<void> cerrarBaseDatos() async {
    if (_database != null) {
      print(
        'PETCARE DIAGNOSTICO: CERRANDO SQLITE',
      );

      await _database!.close();

      _database = null;

      print(
        'PETCARE DIAGNOSTICO: SQLITE CERRADA',
      );
    }
  }

  // =========================================================
  // ELIMINAR TODA LA BASE LOCAL
  // =========================================================

  Future<void> eliminarBaseDatos() async {
    print(
      '=====================================================',
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'INICIANDO ELIMINACION DE SQLITE',
    );

    print(
      '=====================================================',
    );

    if (_database != null) {
      print(
        'PETCARE DIAGNOSTICO: '
        'BASE ABIERTA, LIMPIANDO TABLAS',
      );

      await diagnosticarBaseDatos();

      await _database!.delete(
        'pets',
      );

      print(
        'PETCARE DIAGNOSTICO: '
        'TABLA PETS LIMPIADA',
      );

      await _database!.delete(
        'pending_operations',
      );

      print(
        'PETCARE DIAGNOSTICO: '
        'TABLA PENDING_OPERATIONS LIMPIADA',
      );

      await _database!.delete(
        'users',
      );

      print(
        'PETCARE DIAGNOSTICO: '
        'TABLA USERS LIMPIADA',
      );

      await _database!.delete(
        'reminders',
      );

      print(
        'PETCARE DIAGNOSTICO: '
        'TABLA REMINDERS LIMPIADA',
      );

      await _database!.delete(
        'appointments',
      );

      print(
        'PETCARE DIAGNOSTICO: '
        'TABLA APPOINTMENTS LIMPIADA',
      );

      await _database!.delete(
        'veterinarians',
      );

      print(
        'PETCARE DIAGNOSTICO: '
        'TABLA VETERINARIANS LIMPIADA',
      );

      await _database!.delete(
        'vaccines',
      );

      print(
        'PETCARE DIAGNOSTICO: '
        'TABLA VACCINES LIMPIADA',
      );

      await _database!.delete(
        'dewormings',
      );

      print(
        'PETCARE DIAGNOSTICO: '
        'TABLA DEWORMINGS LIMPIADA',
      );

      await diagnosticarBaseDatos();

      await _database!.close();

      _database = null;

      print(
        'PETCARE DIAGNOSTICO: '
        'CONEXION SQLITE CERRADA',
      );
    } else {
      print(
        'PETCARE DIAGNOSTICO: '
        'LA CONEXION SQLITE YA ESTABA CERRADA',
      );
    }

    // =======================================================
    // OBTENER RUTA DEL ARCHIVO
    // =======================================================

    final databasePath =
        await getDatabasesPath();

    final path = join(
      databasePath,
      'petcare.db',
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'ELIMINANDO ARCHIVO = $path',
    );

    // =======================================================
    // ELIMINAR ARCHIVO FISICO
    // =======================================================

    await deleteDatabase(path);

    print(
      'PETCARE DIAGNOSTICO: '
      'ARCHIVO SQLITE ELIMINADO',
    );

    print(
      '=====================================================',
    );

    print(
      'PETCARE DIAGNOSTICO: '
      'ELIMINACION FINALIZADA',
    );

    print(
      '=====================================================',
    );
  }
}


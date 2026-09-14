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
      version: 2,
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

    // ---------------------------------------------------------
    // TABLA DE MASCOTAS
    // ---------------------------------------------------------

    await db.execute('''
      CREATE TABLE pets (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        especie TEXT NOT NULL,
        raza TEXT NOT NULL,
        edad INTEGER NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ---------------------------------------------------------
    // TABLA DE OPERACIONES PENDIENTES
    // ---------------------------------------------------------

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

    // ---------------------------------------------------------
    // TABLA DE USUARIOS
    // ---------------------------------------------------------

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
      'PETCARE DIAGNOSTICO: TABLAS CREADAS CORRECTAMENTE',
    );
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
      'PETCARE DIAGNOSTICO: MIGRACION $oldVersion -> $newVersion',
    );

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
        'PETCARE DIAGNOSTICO: TABLA USERS CREADA EN MIGRACION',
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
      'PETCARE DIAGNOSTICO: REGISTRANDO USUARIO $correoNormalizado',
    );

    // ---------------------------------------------------------
    // COMPROBAR SI EL CORREO YA EXISTE
    // ---------------------------------------------------------

    final usuariosExistentes = await db.query(
      'users',
      where: 'correo = ?',
      whereArgs: [correoNormalizado],
      limit: 1,
    );

    print(
      'PETCARE DIAGNOSTICO: USUARIOS CON ESE CORREO = ${usuariosExistentes.length}',
    );

    if (usuariosExistentes.isNotEmpty) {
      return false;
    }

    // ---------------------------------------------------------
    // GENERAR SALT ALEATORIO
    // ---------------------------------------------------------

    final salt = _uuid.v4();

    // ---------------------------------------------------------
    // GENERAR HASH
    // ---------------------------------------------------------

    final passwordHash =
        _generarHashPassword(
      password,
      salt,
    );

    // ---------------------------------------------------------
    // GUARDAR USUARIO
    // ---------------------------------------------------------

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
      'PETCARE DIAGNOSTICO: USUARIO GUARDADO CORRECTAMENTE',
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
      'PETCARE DIAGNOSTICO: BUSQUEDA DE $correoNormalizado -> ${resultados.length} RESULTADO(S)',
    );

    if (resultados.isEmpty) {
      return null;
    }

    return resultados.first;
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
      'PETCARE DIAGNOSTICO: VALIDANDO LOGIN PARA $correo',
    );

    await diagnosticarUsuarios();

    final usuario =
        await obtenerUsuarioPorCorreo(
      correo,
    );

    // ---------------------------------------------------------
    // USUARIO NO EXISTE
    // ---------------------------------------------------------

    if (usuario == null) {
      print(
        'PETCARE DIAGNOSTICO: USUARIO NO EXISTE',
      );

      return null;
    }

    // ---------------------------------------------------------
    // OBTENER SALT Y HASH GUARDADOS
    // ---------------------------------------------------------

    final salt =
        usuario['password_salt'] as String;

    final passwordHashGuardado =
        usuario['password_hash'] as String;

    // ---------------------------------------------------------
    // GENERAR HASH CON LA CONTRASEÑA INGRESADA
    // ---------------------------------------------------------

    final passwordHashIngresado =
        _generarHashPassword(
      password,
      salt,
    );

    // ---------------------------------------------------------
    // COMPARAR CONTRASEÑAS
    // ---------------------------------------------------------

    if (passwordHashIngresado !=
        passwordHashGuardado) {
      print(
        'PETCARE DIAGNOSTICO: CONTRASEÑA INCORRECTA',
      );

      return null;
    }

    print(
      'PETCARE DIAGNOSTICO: CREDENCIALES CORRECTAS',
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
          (map) => Pet.fromMap(map),
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
      operation,
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

    return await db.query(
      'pending_operations',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
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
      values,
      where: 'operation_id = ?',
      whereArgs: [operationId],
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
      'PETCARE DIAGNOSTICO: USUARIOS EN SQLITE = $cantidad',
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
      'SELECT COUNT(*) AS cantidad FROM pending_operations',
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
      'OPERACIONES PENDIENTES: ${operaciones.first['cantidad']}',
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
      'PETCARE DIAGNOSTICO: INICIANDO ELIMINACION DE SQLITE',
    );
    print(
      '=====================================================',
    );

    // ---------------------------------------------------------
    // SI LA BASE ESTA ABIERTA, ELIMINAR LAS TABLAS
    // ---------------------------------------------------------

    if (_database != null) {
      print(
        'PETCARE DIAGNOSTICO: BASE ABIERTA, LIMPIANDO TABLAS',
      );

      await diagnosticarBaseDatos();

      await _database!.delete(
        'pets',
      );

      print(
        'PETCARE DIAGNOSTICO: TABLA PETS LIMPIADA',
      );

      await _database!.delete(
        'pending_operations',
      );

      print(
        'PETCARE DIAGNOSTICO: TABLA PENDING_OPERATIONS LIMPIADA',
      );

      await _database!.delete(
        'users',
      );

      print(
        'PETCARE DIAGNOSTICO: TABLA USERS LIMPIADA',
      );

      await diagnosticarBaseDatos();

      await _database!.close();

      _database = null;

      print(
        'PETCARE DIAGNOSTICO: CONEXION SQLITE CERRADA',
      );
    } else {
      print(
        'PETCARE DIAGNOSTICO: LA CONEXION SQLITE YA ESTABA CERRADA',
      );
    }

    // ---------------------------------------------------------
    // OBTENER RUTA DEL ARCHIVO
    // ---------------------------------------------------------

    final databasePath =
        await getDatabasesPath();

    final path = join(
      databasePath,
      'petcare.db',
    );

    print(
      'PETCARE DIAGNOSTICO: ELIMINANDO ARCHIVO = $path',
    );

    // ---------------------------------------------------------
    // ELIMINAR ARCHIVO FISICO
    // ---------------------------------------------------------

    await deleteDatabase(path);

    print(
      'PETCARE DIAGNOSTICO: ARCHIVO SQLITE ELIMINADO',
    );

    print(
      '=====================================================',
    );
    print(
      'PETCARE DIAGNOSTICO: ELIMINACION FINALIZADA',
    );
    print(
      '=====================================================',
    );
  }
}
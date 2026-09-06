import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/pet.dart';

class DatabaseService {
  DatabaseService._privateConstructor();

  static final DatabaseService instance =
      DatabaseService._privateConstructor();

  Database? _database;

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

    return await openDatabase(
      path,
      version: 1,
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
  }

  // =========================================================
  // MIGRACIONES
  // =========================================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Aquí agregaremos futuras migraciones.
    }
  }

  // =========================================================
  // INSERTAR MASCOTA
  // =========================================================

  Future<void> insertarMascota(Pet pet) async {
    final db = await database;

    await db.insert(
      'pets',
      pet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
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

  Future<void> actualizarMascota(Pet pet) async {
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

  Future<void> eliminarMascota(String id) async {
    final db = await database;

    await db.update(
      'pets',
      {
        'deleted': 1,
        'sync_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================================================
  // OPERACIONES PENDIENTES
  // =========================================================

  Future<void> insertarOperacionPendiente(
    Map<String, dynamic> operation,
  ) async {
    final db = await database;

    await db.insert(
      'pending_operations',
      operation,
      conflictAlgorithm: ConflictAlgorithm.replace,
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
  // CERRAR BASE DE DATOS
  // =========================================================

  Future<void> cerrarBaseDatos() async {
    if (_database != null) {
      await _database!.close();

      _database = null;
    }
  }

  // =========================================================
  // ELIMINAR TODA LA BASE LOCAL
  // =========================================================

  Future<void> eliminarBaseDatos() async {
    await cerrarBaseDatos();

    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'petcare.db',
    );

    await deleteDatabase(path);
  }
}
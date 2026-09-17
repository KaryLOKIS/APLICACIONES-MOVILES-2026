import 'package:dio/dio.dart';

import '../../config/api_config.dart';
import '../../models/pet.dart';
import '../../services/api_client.dart';

class PetRemoteDataSource {
  PetRemoteDataSource({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  // ==========================================================
  // OBTENER MASCOTAS DESDE EL SERVIDOR
  // ==========================================================

  Future<List<Pet>> obtenerMascotas() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.petsEndpoint,
      );

      final data = response.data;

      // El backend responde:
      // {
      //   "datos": [...],
      //   "total": 1
      // }

      if (data is! Map) {
        throw Exception(
          'La respuesta del servidor no tiene un formato válido.',
        );
      }

      final listaMascotas = data['datos'];

      if (listaMascotas is! List) {
        throw Exception(
          'La respuesta del servidor no contiene una lista de mascotas válida.',
        );
      }

      return listaMascotas
          .map(
            (item) => Pet.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException {
      rethrow;
    }
  }

  // ==========================================================
  // CREAR MASCOTA EN EL SERVIDOR
  // ==========================================================

  Future<Pet> crearMascota(Pet pet) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.petsEndpoint,
        data: {
          'id': pet.id,
          'nombre': pet.nombre,
          'especie': pet.especie,
          'raza': pet.raza,
          'edad': pet.edad,
        },
      );

      final data = response.data;

      // El backend responde:
      // {
      //   "mensaje": "...",
      //   "datos": {
      //      ...
      //   },
      //   "idempotente": false
      // }

      if (data is! Map) {
        throw Exception(
          'La respuesta del servidor no tiene un formato válido.',
        );
      }

      final mascotaData = data['datos'];

      if (mascotaData is! Map) {
        throw Exception(
          'La respuesta del servidor no contiene los datos de la mascota.',
        );
      }

      return Pet.fromMap(
        Map<String, dynamic>.from(mascotaData),
      );
    } on DioException {
      rethrow;
    }
  }

  // ==========================================================
  // ELIMINAR MASCOTA
  // ==========================================================

  Future<void> eliminarMascota(String id) async {
    try {
      await _apiClient.dio.delete(
        '${ApiConfig.petsEndpoint}/$id',
      );
    } on DioException {
      rethrow;
    }
  }
}
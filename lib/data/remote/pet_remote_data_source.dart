import 'package:dio/dio.dart';

import '../../config/api_config.dart';
import '../../models/pet.dart';
import '../../services/api_client.dart';

class PetRemoteDataSource {
  PetRemoteDataSource({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  // =========================================================
  // OBTENER MASCOTAS
  // =========================================================

  Future<List<Pet>> obtenerMascotas() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.petsEndpoint,
      );

      final data = response.data;

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
            (item) => Pet.fromJson(
              Map<String, dynamic>.from(
                item as Map,
              ),
            ),
          )
          .toList();
    } on DioException {
      rethrow;
    }
  }

  // =========================================================
  // CREAR MASCOTA
  // =========================================================

  Future<Pet> crearMascota(Pet pet) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.petsEndpoint,
        data: pet.toJson(),
      );

      final data = response.data;

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

      return Pet.fromJson(
        Map<String, dynamic>.from(
          mascotaData,
        ),
      );
    } on DioException {
      rethrow;
    }
  }

  // =========================================================
  // ACTUALIZAR MASCOTA
  // =========================================================

  Future<Pet> actualizarMascota(Pet pet) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConfig.petsEndpoint}/${pet.id}',
        data: {
          'nombre': pet.nombre,
          'especie': pet.especie,
          'raza': pet.raza,
          'edad': pet.edad,
          'peso': pet.peso,
          'alergias': pet.alergias,
        },
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception(
          'La respuesta del servidor no tiene un formato válido.',
        );
      }

      final mascotaData = data['datos'];

      if (mascotaData is! Map) {
        throw Exception(
          'La respuesta del servidor no contiene los datos de la mascota actualizada.',
        );
      }

      return Pet.fromJson(
        Map<String, dynamic>.from(
          mascotaData,
        ),
      );
    } on DioException {
      rethrow;
    }
  }

  // =========================================================
  // ELIMINAR MASCOTA
  // =========================================================

  Future<void> eliminarMascota(
    String id,
  ) async {
    try {
      await _apiClient.dio.delete(
        '${ApiConfig.petsEndpoint}/$id',
      );
    } on DioException {
      rethrow;
    }
  }
}
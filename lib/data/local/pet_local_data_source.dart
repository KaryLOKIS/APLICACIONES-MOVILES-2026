import '../../models/pet.dart';
import '../../services/database_service.dart';

class PetLocalDataSource {
  PetLocalDataSource({
    DatabaseService? databaseService,
  }) : _databaseService =
            databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  Future<List<Pet>> obtenerMascotas() async {
    return _databaseService.obtenerMascotas();
  }

  Future<void> guardarMascota(Pet pet) async {
    await _databaseService.insertarMascota(pet);
  }

  Future<void> actualizarMascota(Pet pet) async {
    await _databaseService.actualizarMascota(pet);
  }

  Future<void> eliminarMascota(String id) async {
    await _databaseService.eliminarMascota(id);
  }

  Future<void> agregarOperacionPendiente(
    Map<String, dynamic> operacion,
  ) async {
    await _databaseService.insertarOperacionPendiente(
      operacion,
    );
  }

  Future<List<Map<String, dynamic>>>
      obtenerOperacionesPendientes() async {
    return _databaseService.obtenerOperacionesPendientes();
  }

  Future<void> actualizarOperacionPendiente(
    String operationId,
    Map<String, dynamic> values,
  ) async {
    await _databaseService.actualizarOperacionPendiente(
      operationId,
      values,
    );
  }
}
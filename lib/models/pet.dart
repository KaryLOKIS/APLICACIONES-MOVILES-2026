import 'package:json_annotation/json_annotation.dart';

part 'pet.g.dart';

@JsonSerializable()
class Pet {
  final String id;
  final String nombre;
  final String especie;
  final String raza;
  final int edad;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  final String syncStatus;
  final bool deleted;

  Pet({
    required this.id,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.edad,
    required this.updatedAt,
    this.syncStatus = 'pending',
    this.deleted = false,
  });

  factory Pet.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$PetFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PetToJson(this);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'especie': especie,
      'raza': raza,
      'edad': edad,
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory Pet.fromMap(
    Map<String, dynamic> map,
  ) {
    return Pet(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      especie: map['especie'] as String,
      raza: map['raza'] as String,
      edad: map['edad'] as int,
      updatedAt: DateTime.parse(
        map['updated_at'] as String,
      ),
      syncStatus:
          map['sync_status'] as String? ?? 'pending',
      deleted:
          (map['deleted'] as int? ?? 0) == 1,
    );
  }

  Pet copyWith({
    String? id,
    String? nombre,
    String? especie,
    String? raza,
    int? edad,
    DateTime? updatedAt,
    String? syncStatus,
    bool? deleted,
  }) {
    return Pet(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      especie: especie ?? this.especie,
      raza: raza ?? this.raza,
      edad: edad ?? this.edad,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deleted: deleted ?? this.deleted,
    );
  }
}
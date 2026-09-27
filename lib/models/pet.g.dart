// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pet _$PetFromJson(Map<String, dynamic> json) => Pet(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  especie: json['especie'] as String,
  raza: json['raza'] as String,
  edad: (json['edad'] as num).toInt(),
  peso: (json['peso'] as num?)?.toDouble(),
  alergias: json['alergias'] as String?,
  updatedAt: DateTime.parse(json['updated_at'] as String),
  syncStatus: json['syncStatus'] as String? ?? 'pending',
  deleted: json['deleted'] as bool? ?? false,
);

Map<String, dynamic> _$PetToJson(Pet instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'especie': instance.especie,
  'raza': instance.raza,
  'edad': instance.edad,
  'peso': instance.peso,
  'alergias': instance.alergias,
  'updated_at': instance.updatedAt.toIso8601String(),
  'syncStatus': instance.syncStatus,
  'deleted': instance.deleted,
};

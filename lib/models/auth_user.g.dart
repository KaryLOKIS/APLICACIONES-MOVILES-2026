// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthUser _$AuthUserFromJson(Map<String, dynamic> json) => AuthUser(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  email: json['email'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$AuthUserToJson(AuthUser instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'email': instance.email,
  'created_at': instance.createdAt.toIso8601String(),
};

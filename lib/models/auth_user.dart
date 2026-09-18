import 'package:json_annotation/json_annotation.dart';

part 'auth_user.g.dart';

@JsonSerializable()
class AuthUser {
  final String id;
  final String nombre;
  final String email;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  AuthUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.createdAt,
  });

  factory AuthUser.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$AuthUserFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AuthUserToJson(this);
}
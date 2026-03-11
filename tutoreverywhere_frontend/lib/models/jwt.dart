import 'package:json_annotation/json_annotation.dart';
part 'jwt.g.dart';

@JsonSerializable()
class Jwt {
  @JsonKey(name: "token")
  String token;

  Jwt({required this.token});

  factory Jwt.fromJson(Map<String, dynamic> json) => _$JwtFromJson(json);

  Map<String, dynamic> toJson() => _$JwtToJson(this);
}

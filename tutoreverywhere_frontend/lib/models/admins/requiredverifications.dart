import 'package:json_annotation/json_annotation.dart';

part 'requiredverifications.g.dart';

@JsonSerializable()
class RequiredVerificationsResponse {
  @JsonKey(name: 'user_uuid') // Replace with actual field name
  final String userId;     // or bool, int, etc.
  @JsonKey(name: 'firstname')
  final String firstname;
  @JsonKey(name: 'lastname')
  final String lastname;
  @JsonKey(name: 'gender')
  final String gender;
  
  RequiredVerificationsResponse({required this.userId, required this.firstname, required this.lastname, required this.gender});
  
  factory RequiredVerificationsResponse.fromJson(Map<String, dynamic> json) => 
      _$RequiredVerificationsResponseFromJson(json);
}
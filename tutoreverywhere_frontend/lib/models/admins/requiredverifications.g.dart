// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'requiredverifications.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequiredVerificationsResponse _$RequiredVerificationsResponseFromJson(
  Map<String, dynamic> json,
) => RequiredVerificationsResponse(
  userId: json['user_uuid'] as String,
  firstname: json['firstname'] as String,
  lastname: json['lastname'] as String,
  gender: json['gender'] as String,
);

Map<String, dynamic> _$RequiredVerificationsResponseToJson(
  RequiredVerificationsResponse instance,
) => <String, dynamic>{
  'user_uuid': instance.userId,
  'firstname': instance.firstname,
  'lastname': instance.lastname,
  'gender': instance.gender,
};

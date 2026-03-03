// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TutorData _$TutorDataFromJson(Map<String, dynamic> json) => TutorData(
  userUuid: json['user_uuid'] as String,
  firstname: json['firstname'] as String,
  lastname: json['lastname'] as String,
  dateofbirth: DateTime.parse(json['dateofbirth'] as String),
  gender: json['gender'] as String,
  profilePicture: json['profile_picture'] as String,
  bio: json['bio'] as String?,
  verified: json['verified'] as bool,
  preferredPlace: json['preferred_place'] as String?,
  zone: json['zone'] as String?,
  province: json['province'] as String?,
  location: json['location'] as String?,
);

Map<String, dynamic> _$TutorDataToJson(TutorData instance) => <String, dynamic>{
  'user_uuid': instance.userUuid,
  'firstname': instance.firstname,
  'lastname': instance.lastname,
  'dateofbirth': instance.dateofbirth.toIso8601String(),
  'gender': instance.gender,
  'profile_picture': instance.profilePicture,
  'bio': instance.bio,
  'verified': instance.verified,
  'preferred_place': instance.preferredPlace,
  'zone': instance.zone,
  'province': instance.province,
  'location': instance.location,
};

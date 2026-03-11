// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterTutor _$RegisterTutorFromJson(Map<String, dynamic> json) =>
    RegisterTutor(
      username: json['username'] as String,
      password: json['password'] as String,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      dateofbirth: _stringToDate(json['dateofbirth'] as String?),
      gender: json['gender'] as String,
    );

Map<String, dynamic> _$RegisterTutorToJson(RegisterTutor instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'firstname': instance.firstname,
      'lastname': instance.lastname,
      'gender': instance.gender,
      'dateofbirth': _dateToString(instance.dateofbirth),
    };

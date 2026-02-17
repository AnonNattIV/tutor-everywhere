// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterStudent _$RegisterStudentFromJson(Map<String, dynamic> json) =>
    RegisterStudent(
      username: json['username'] as String,
      password: json['password'] as String,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      dateofbirth: _stringToDate(json['dateofbirth'] as String?),
      gender: json['gender'] as String,
    );

Map<String, dynamic> _$RegisterStudentToJson(RegisterStudent instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'firstname': instance.firstname,
      'lastname': instance.lastname,
      'gender': instance.gender,
      'dateofbirth': _dateToString(instance.dateofbirth),
    };

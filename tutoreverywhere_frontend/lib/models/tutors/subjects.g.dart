// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subjects.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TutorSubject _$TutorSubjectFromJson(Map<String, dynamic> json) => TutorSubject(
  tutorUuid: json['tutor_uuid'] as String,
  subject: json['subject'] as String,
  price: (json['price'] as num).toInt(),
);

Map<String, dynamic> _$TutorSubjectToJson(TutorSubject instance) =>
    <String, dynamic>{
      'tutor_uuid': instance.tutorUuid,
      'subject': instance.subject,
      'price': instance.price,
    };

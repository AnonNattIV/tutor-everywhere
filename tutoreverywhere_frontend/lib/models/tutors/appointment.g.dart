// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Appointment _$AppointmentFromJson(Map<String, dynamic> json) => Appointment(
  appointmentId: json['appointment_id'] as String,
  tutorId: json['tutor_id'] as String,
  tutorFirstname: json['tutor_firstname'] as String,
  tutorLastname: json['tutor_lastname'] as String,
  tutorVerified: json['tutor_verified'] as bool,
  studentId: json['student_id'] as String,
  studentFirstname: json['student_firstname'] as String,
  studentLastname: json['student_lastname'] as String,
  studentVerified: json['student_verified'] as bool,
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: DateTime.parse(json['end_date'] as String),
  placeName: json['place_name'] as String?,
  description: json['description'] as String?,
  subject: json['subject'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AppointmentToJson(Appointment instance) =>
    <String, dynamic>{
      'appointment_id': instance.appointmentId,
      'tutor_id': instance.tutorId,
      'tutor_firstname': instance.tutorFirstname,
      'tutor_lastname': instance.tutorLastname,
      'tutor_verified': instance.tutorVerified,
      'student_id': instance.studentId,
      'student_firstname': instance.studentFirstname,
      'student_lastname': instance.studentLastname,
      'student_verified': instance.studentVerified,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'place_name': instance.placeName,
      'description': instance.description,
      'subject': instance.subject,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

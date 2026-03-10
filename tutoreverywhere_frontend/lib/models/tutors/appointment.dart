import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

@JsonSerializable()
class Appointment {
  @JsonKey(name: 'appointment_id')
  final String appointmentId;
  
  @JsonKey(name: 'tutor_id')
  final String tutorId;
  
  @JsonKey(name: 'tutor_firstname')
  final String tutorFirstname;
  
  @JsonKey(name: 'tutor_lastname')
  final String tutorLastname;
  
  @JsonKey(name: 'tutor_verified')
  final bool tutorVerified;
  
  @JsonKey(name: 'student_id')
  final String studentId;
  
  @JsonKey(name: 'student_firstname')
  final String studentFirstname;
  
  @JsonKey(name: 'student_lastname')
  final String studentLastname;
  
  @JsonKey(name: 'student_verified')
  final bool studentVerified;
  
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  
  @JsonKey(name: 'place_name')
  final String? placeName;
  
  final String? description;

  final String? subject;

  final double? latitude;

  final double? longitude;

  Appointment({
    required this.appointmentId,
    required this.tutorId,
    required this.tutorFirstname,
    required this.tutorLastname,
    required this.tutorVerified,
    required this.studentId,
    required this.studentFirstname,
    required this.studentLastname,
    required this.studentVerified,
    required this.startDate,
    required this.endDate,
    this.placeName,
    this.description,
    this.subject,
    this.latitude,
    this.longitude
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => 
      _$AppointmentFromJson(json);
  
  Map<String, dynamic> toJson() => _$AppointmentToJson(this);
}
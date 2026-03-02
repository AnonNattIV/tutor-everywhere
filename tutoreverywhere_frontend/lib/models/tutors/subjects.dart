import 'package:json_annotation/json_annotation.dart';

part 'subjects.g.dart';

@JsonSerializable()
class TutorSubject {
  @JsonKey(name: 'tutor_uuid')
  final String tutorUuid;
  
  final String subject;
  
  final int price;

  TutorSubject({
    required this.tutorUuid,
    required this.subject,
    required this.price,
  });

  factory TutorSubject.fromJson(Map<String, dynamic> json) =>
      _$TutorSubjectFromJson(json);

  Map<String, dynamic> toJson() => _$TutorSubjectToJson(this);
}
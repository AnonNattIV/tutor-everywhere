import 'package:json_annotation/json_annotation.dart';

part 'data.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TutorData {
  final String userUuid;
  final String firstname;
  final String lastname;
  final DateTime dateofbirth;
  final String gender;
  final String profilePicture;
  final String? bio;

  TutorData({
    required this.userUuid,
    required this.firstname,
    required this.lastname,
    required this.dateofbirth,
    required this.gender,
    required this.profilePicture,
    this.bio,
  });

  factory TutorData.fromJson(Map<String, dynamic> json) => _$TutorDataFromJson(json);
  Map<String, dynamic> toJson() => _$TutorDataToJson(this);
}